require 'snmp' # http://snmplib.rubyforge.org/doc/index.html
require 'polling'

module Fluent
  class SnmpInput < Input
    Plugin.register_input('snmp', self)

    # Fluent Params
    # require param: tag, mib
    config_param :tag, :string
    config_param :mib, :string
    config_param :nodes, :string, :default => nil 
    config_param :polling_time, :string, :default => nil
    config_param :polling_offset, :time, :default => 0
    config_param :polling_type, :string, :default => "run" #or async_run
    config_param :method_type, :string, :default => "walk" #or get
    config_param :out_executor, :string, :default => nil

    # SNMP Lib Params
    # require param: host, community
    #
    # Option              Default Value
    # --------------------------------------
    # :host               'localhost'
    # :port               161
    # :trap_port          162
    # :community          'public'
    # :write_community    Same as :community
    # :version            :SNMPv2c
    # :timeout            1 (timeout units are seconds)
    # :retries            5
    # :transport          UDPTransport
    # :max_recv_bytes     8000 bytes
    # :mib_dir            MIB::DEFAULT_MIB_PATH
    # :mib_modules        SNMPv2-SMI, SNMPv2-MIB, IF-MIB, IP-MIB, TCP-MIB, UDP-MIB
    # :use_IPv6           false, unless :host is formatted like an IPv6 address
    config_param :host, :string
    config_param :port, :integer, :default => nil
    config_param :trap_port, :integer, :default => nil
    config_param :community, :string
    config_param :write_community, :string, :default => nil
    config_param :version, :string, :default => nil # Use :SNMPv1 or :SNMPv2c
    config_param :timeout, :time, :default => nil
    config_param :retries, :integer, :default => nil
    config_param :transport, :string, :default => nil
    config_param :max_recv_bytes, :string, :default => nil
    config_param :mib_dir, :string, :default => nil
    config_param :mib_modules, :string, :default => nil
    config_param :use_IPv6, :string, :default => nil

    def configure(conf)                                                         
      super

      raise ConfigError, "snmp: 'tag' is required param" if @tag.empty?
      raise ConfigError, "snmp: 'polling_type' parameter is required on snmp input" if @polling_type.empty?

      # @mib, @mib_modules, @nodesを配列に変換
      @mib = @mib.split(',').map{|str| str.strip} 
      raise ConfigError, "snmp: 'mib' parameter is required on snmp input" if @mib.empty?

      @mib_modules = @mib_modules.split(',').map{|str| str.strip} unless @mib_modules.nil?
      raise ConfigError, "snmp: 'mib_modules' parameter is required on snmp input" if !@mib_modules.nil? && @mib_modules.empty?

      @nodes = @nodes.split(',').map{|str| str.strip} unless @nodes.nil?
      raise ConfigError, "snmp: 'nodes' parameter is required on snmp input" if !@nodes.nil? && @nodes.empty?

      @polling_time = @polling_time.split(',').map{|str| str.strip} unless @polling_time.nil?
      raise ConfigError, "snmp: 'polling_time' parameter is required on snmp input" if !@polling_time.nil? && @polling_time.empty?

      # snmp version
      @version = @version == "1" ? :SNMPv1 : :SNMPv2c

      # SNMP Libraryの初期値を設定
      @snmp_init_params = {
        :host            => @host, #or conf["host"]
        :port            => @port,
        :trap_port       => @trap_port,
        :community       => @community,
        :write_community => @write_community,
        :version         => @version,
        :timeout         => @timeout,
        :retries         => @retries,
        :transport       => @transport,
        :max_recv_bytes  => @max_recv_bytes,
        :mib_dir         => @mib_dir,
        :mib_modules     => @mib_modules,
        :use_IPv6        => @use_IPv6
      }

      unless @out_executor.nil?
        $log.info "load snmp out executor #{out_executor}"
        @out_exec = lambda do |manager|
          load @out_executor
          opts = {
            :tag         => @tag,
            :mib         => @mib,
            :mib_modules => @mib_modules,
            :nodes       => @nodes,
            :conf        => conf
          }
          Fluent::SnmpInput.new.out_exec(manager, opts)
        end
      end
    end

    def start
      @manager = SNMP::Manager.new(@snmp_init_params)
      @thread = Thread.new(&method(:run))
      @end_flag = false
    end

    def run
      Polling.setting offset: @polling_offset
      Polling.__send__(@polling_type, @polling_time) do
        break if @end_flag
        exec_snmp(manager: @manager, mib: @mib, nodes: @nodes, method_type: @method_type)
      end
    rescue TypeError => ex
      $log.error "run TypeError", :error=>ex.message
      exit
    rescue => ex
      $log.fatal "run failed", :error=>ex.inspect
      $log.error_backtrace ex.backtrace
      exit
    end

    def shutdown
      @end_flag = true
      if @thread 
        @thread.run
        @thread.join
        @thread = nil
      end
      if @manager
        @manager.close 
      end
    end

    private

    def exec_snmp opts={}
      if @out_executor.nil?
        case opts[:method_type]
        when /^walk$/
          snmp_walk(opts[:manager], opts[:mib], opts[:nodes])
        when /^get$/
          snmp_get(opts[:manager], opts[:mib], opts[:nodes])
        else
          $log.error "unknow exec method"
          raise
        end
      else
        @out_exec.call opts[:manager]
      end
    rescue SNMP::RequestTimeout => ex
      $log.error "exec_snmp failed #{@tag}", :error=>ex.inspect
    rescue => ex
      $log.error "exec_snmp failed #{@tag}", :error=>ex.inspect
      $log.error_backtrace ex.backtrace
      raise ex
    end

    def snmp_walk(manager, mib, nodes, test=false)
      manager.walk(mib) do |row|
        time = Engine.now 
        time = time - time % 5
        record = {}
        row.each do |vb|
          if nodes.nil?
            record["value"] = vb
          else
            nodes.each{|param| record[param] = check_type(vb.__send__(param))}
          end
          Engine.emit(@tag, time, record)
          return {:time => time, :record => record} if test
        end
      end
    rescue => ex
      raise ex
    end

    def snmp_get(manager, mib, nodes, test=false)
      manager.get(mib).each_varbind do |vb|
        time = Engine.now
        time = time - time % 5
        record = {}
        if nodes.nil?
          record["value"] = vb
        else
          nodes.each{|param| record[param] = check_type(vb.__send__(param))}
        end
        Engine.emit(@tag, time, record)
        return {:time => time, :record => record} if test
      end
    rescue => ex
      raise ex
    end

    # data check from snmp
    def check_type(value)
      if value =~ /^\d+(\.\d+)?$/ 
        return value.to_f
      elsif SNMP::Integer === value
        return value.to_i
      else
        return value.to_s
      end
    rescue => ex
      $log.error "snmp failed to check_type", :error=>ex.message
      $log.warn_backtrace ex.backtrace
    end
  end
end
