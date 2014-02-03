require 'helper'
require 'mocha/setup'
require 'time'

class SnmpInputTest < Test::Unit::TestCase

  def setup
    Fluent::Test.setup
    @obj = Fluent::SnmpInput.new
  end

  CONFIG = %[
    tag snmp.server1
    mib hrStorageIndex, hrStorageDescr, hrStorageSize, hrStorageUsed
    nodes name, value
    polling_time 0,10,20,30,40,50
    polling_offset 0
    host localhost
    community public
    mib_modules HOST-RESOURCES-MIB, IF-MIB
    timeout 3s
    method_type walk
    out_executor sample/out_exec.rb.sample
  ]

  def create_driver(conf=CONFIG)
    Fluent::Test::InputTestDriver.new(Fluent::SnmpInput).configure(conf)
  end

  def test_configure
    d = create_driver

    # Fluent Params
    assert_equal "snmp.server1", d.instance.tag
    assert_equal ["hrStorageIndex","hrStorageDescr","hrStorageSize","hrStorageUsed"], d.instance.mib
    assert_equal ["name","value"], d.instance.nodes
    assert_equal ["0","10","20","30","40","50"], d.instance.polling_time
    assert_equal 0, d.instance.polling_offset
    assert_equal "walk", d.instance.method_type
    assert_equal "sample/out_exec.rb.sample", d.instance.out_executor

    # SNMP Lib Params
    assert_equal "localhost", d.instance.host
    assert_nil d.instance.port
    assert_nil d.instance.trap_port
    assert_equal "public", d.instance.community
    assert_nil d.instance.write_community
    assert_equal :SNMPv2c, d.instance.version
    assert_equal 3, d.instance.timeout
    assert_nil d.instance.transport
    assert_nil d.instance.max_recv_bytes
    assert_nil d.instance.mib_dir
    assert_equal ["HOST-RESOURCES-MIB","IF-MIB"], d.instance.mib_modules
    assert_nil d.instance.use_IPv6
  end

  def test_check_type
    assert_equal "test", @obj.__send__(:check_type,"test")
    assert_equal "utrh0", @obj.__send__(:check_type,"utrh0")
    assert_equal "sensorValue_degC", @obj.__send__(:check_type,"sensorValue_degC")
    assert_equal "sensorValue_%RH", @obj.__send__(:check_type,"sensorValue_%RH")
    assert_equal 12.00, @obj.__send__(:check_type,"12")
    assert_equal 12.34, @obj.__send__(:check_type,"12.34")
    assert_equal String, @obj.__send__(:check_type,"test").class
    assert_equal String, @obj.__send__(:check_type,"utrh0").class
    assert_equal String, @obj.__send__(:check_type,"sensorValue_degC").class
    assert_equal String, @obj.__send__(:check_type,"sensorValue_%RH").class
    assert_equal Float, @obj.__send__(:check_type,"12").class
    assert_equal Float, @obj.__send__(:check_type,"12.34").class
  end

  def test_snmp_walk
    d = create_driver
    nodes = d.instance.nodes
    mib = d.instance.mib

    snmp_init_params = {
      :host => d.instance.host,
      :community => d.instance.community,
      :timeout => d.instance.timeout,
      :retries => d.instance.retries,
      :mib_dir => d.instance.mib_dir,
      :mib_modules => d.instance.mib_modules,
    }

    # unixtime 1356965990
    Time.stubs(:now).returns(Time.parse "2012/12/31 23:59:50")
    manager = SNMP::Manager.new(snmp_init_params)

    data = @obj.__send__(:snmp_walk, manager, mib, nodes, true)
    record = data[:record]

    assert_equal 1356965990, data[:time]
    assert_equal "HOST-RESOURCES-MIB::hrStorageIndex.1", record["name"]
    assert_equal "1", record["value"]
  end


  def test_snmp_get
    d = create_driver %[
      tag snmp.server1
      mib hrStorageIndex.31
      nodes name, value
      polling_time 0,10,20,30,40,50
      host localhost
      community public
      mib_modules HOST-RESOURCES-MIB
    ]
    nodes = d.instance.nodes
    mib = d.instance.mib

    snmp_init_params = {
      :host => d.instance.host,
      :community => d.instance.community,
      :timeout => d.instance.timeout,
      :retries => d.instance.retries,
      :mib_dir => d.instance.mib_dir,
      :mib_modules => d.instance.mib_modules,
    }

    # unixtime 1356965990
    Time.stubs(:now).returns(Time.parse "2012/12/31 23:59:50")
    manager = SNMP::Manager.new(snmp_init_params)

    data = @obj.__send__(:snmp_get, manager, mib, nodes, true)
    record = data[:record]

    assert_equal 1356965990, data[:time]
    assert_equal "HOST-RESOURCES-MIB::hrStorageIndex.31", record["name"]
    assert_equal "31", record["value"]
  end

  def test_exec_snmp
    d = create_driver
    snmp_init_params = {
      :host => d.instance.host,
      :community => d.instance.community,
      :timeout => d.instance.timeout,
      :retries => d.instance.retries,
      :mib_dir => d.instance.mib_dir,
      :mib_modules => d.instance.mib_modules,
    }

    manager = SNMP::Manager.new(snmp_init_params)

    opts = {
      :manager => manager,
      :method_type => d.instance.method_type,
      :mib => d.instance.mib,
      :nodes => d.instance.nodes,
      :test => true
    }

    exec = @obj.__send__(:exec_snmp, opts)
    assert_equal nil, exec
  end
end
