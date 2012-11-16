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
    config_param :host_name, :string, :default => nil

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

    def initialize
      super
    end  

    def configure(conf)                                                         
      super

      raise ConfigError, "tag is required param" if @tag.empty?

      # @mib, @mib_modules, @nodesを配列に変換
      @mib = @mib.split(',').map{|str| str.strip} 
      raise ConfigError, "snmp: 'mib' parameter is required on snmp input" if @mib.empty?

      @mib_modules = @mib_modules.split(',').map{|str| str.strip} unless @mib_modules.nil?
      raise ConfigError, "snmp: 'mib_modules' parameter is required on snmp input" if !@mib_modules.nil? && @mib_modules.empty?

      @nodes = @nodes.split(',').map{|str| str.strip} unless @nodes.nil?
      raise ConfigError, "snmp: 'nodes' parameter is required on snmp input" if !@nodes.nil? && @nodes.empty?

      @polling_time = @polling_time.split(',').map{|str| str.strip.to_i} unless @polling_time.nil?
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

      @retry_conut = 0
    end

    def starter
      @starter = Thread.new do
        yield
      end
    end

    def start
      starter do
        @manager = SNMP::Manager.new(@snmp_init_params)
        @thread = Thread.new(&method(:run))
        @end_flag = false
      end
    end

    def run
      Polling::run(@polling_time) do
        snmpwalk(@manager, @mib, @nodes)
        break if @end_flag
      end
    rescue TypeError => ex
      $log.error "run TypeError", :error=>ex.message
      exit
    rescue => ex
      $log.error "run failed", :error=>ex.message
      sleep(10)
      @retry_conut += 1
      retry if @retry_conut < 30
    end

    #Ctrl-cで処理を停止時に呼ばれる
    def shutdown
      @end_flag = true
      @thread.run
      @thread.join
      @starter.join
      @manager.close 
    end

    private

    def snmpwalk(manager, mib, nodes = nil, test = false)
      manager.walk(mib) do |row|
        time = Engine.now 
        time = time - time % 5
        record = Hash.new
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
    end

    # SNMPで取得したデータの型チェック
    def check_type(value)
      if value =~ /^\d+(\.\d+)?$/ 
        return value.to_f
      else
        return value.to_s
      end
    rescue => ex
      $Log.error "snmp failed to check_type", :error=>ex.message
      $log.warn_backtrace ex.backtrace
    end

  end
end
