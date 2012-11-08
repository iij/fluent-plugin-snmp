require 'helper'
require 'flexmock'

class SnmpInputTest < Test::Unit::TestCase
  include FlexMock::TestCase

  def setup
    Fluent::Test.setup
  end

  CONFIG = %[
    tag snmp.server1
    mib hrStorageIndex, hrStorageDescr, hrStorageSize, hrStorageUsed
    nodes name, value
    polling_time 0,10,20,30,40,50
    polling_interval 60s
    host localhost
    community private
    mib_modules HOST-RESOURCES-MIB, IF-MIB
    retries 0
    timeout 3s
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
    assert_equal [0,10,20,30,40,50], d.instance.polling_time
    assert_equal 60, d.instance.polling_interval

    # SNMP Lib Params
    assert_equal "localhost", d.instance.host
    assert_nil d.instance.port
    assert_nil d.instance.trap_port
    assert_equal "private", d.instance.community
    assert_nil d.instance.write_community
    assert_equal :SNMPv2c, d.instance.version
    assert_equal 3, d.instance.timeout
    assert_equal 0, d.instance.retries
    assert_nil d.instance.transport
    assert_nil d.instance.max_recv_bytes
    assert_nil d.instance.mib_dir
    assert_equal ["HOST-RESOURCES-MIB","IF-MIB"], d.instance.mib_modules
    assert_nil d.instance.use_IPv6
  end

  def test_run
    d = create_driver

    snmp_init_params = {
      :host => d.instance.host,
      :port => d.instance.host,
      :trap_port => d.instance.trap_port,
      :community => d.instance.community,
      :write_community => d.instance.write_community,
      :version => d.instance.version,
      :timeout => d.instance.timeout,
      :retries => d.instance.retries,
      :transport => d.instance.transport,
      :max_recv_bytes => d.instance.max_recv_bytes,
      :mib_dir => d.instance.mib_dir,
      :mib_modules => d.instance.mib_modules,
      :use_IPv6 => d.instance.use_IPv6
    }
  end

  def test_check_type
    d = Fluent::SnmpInput.new
    hoge = d.check_type("hoge")
    assert_equal "hoge",hoge
  end

end
