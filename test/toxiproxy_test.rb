require 'test_helper'

class ToxiproxyTest < MiniTest::Unit::TestCase
  def teardown
    Toxiproxy.grep(/\Atest_/).each(&:destroy)
  end

  def test_create_proxy
    proxy = Toxiproxy.create(upstream: "localhost:3306", name: "test_mysql_master")

    assert_equal "localhost:3306", proxy.upstream
    assert_equal "test_mysql_master", proxy.name
  end

  def test_create_and_find_proxy
    proxy = Toxiproxy.create(upstream: "localhost:3306", name: "test_mysql_master")

    assert_equal "localhost:3306", proxy.upstream
    assert_equal "test_mysql_master", proxy.name

    proxy = Toxiproxy[:test_mysql_master]

    assert_equal "localhost:3306", proxy.upstream
    assert_equal "test_mysql_master", proxy.name
  end

  def test_take_endpoint_down
    with_tcpserver do |port|
      proxy = Toxiproxy.create(upstream: "localhost:#{port}", name: "test_rubby_server")
      listen_addr = proxy.listen

      proxy.down do
        assert_proxy_unavailable proxy
      end

      assert_proxy_available proxy

      assert_equal listen_addr, proxy.listen
    end
  end

  def test_raises_when_proxy_doesnt_exist
    assert_raises Toxiproxy::NotFound do
      Toxiproxy[:does_not_exist]
    end
  end

  def test_proxies_all_returns_proxy_collection
    assert_instance_of Toxiproxy::Collection, Toxiproxy.all
  end

  def test_down_on_proxy_collection_disables_entire_collection
    with_tcpserver do |port1|
      with_tcpserver do |port2|
        proxy1 = Toxiproxy.create(upstream: "localhost:#{port1}", name: "test_proxy1")
        proxy2 = Toxiproxy.create(upstream: "localhost:#{port2}", name: "test_proxy2")

        assert_proxy_available proxy2
        assert_proxy_available proxy1

        Toxiproxy.all.down do
          assert_proxy_unavailable proxy1
          assert_proxy_unavailable proxy2
        end

        assert_proxy_available proxy2
        assert_proxy_available proxy1
      end
    end
  end

  def test_select_from_toxiproxy_collection
    with_tcpserver do |port|
      Toxiproxy.create(upstream: "localhost:#{port}", name: "test_proxy")

      proxies = Toxiproxy.select { |p| p.upstream == "localhost:#{port}" }

      assert_equal 1, proxies.size
      assert_instance_of Toxiproxy::Collection, proxies
    end
  end

  def test_grep_returns_toxiproxy_collection
    with_tcpserver do |port|
      Toxiproxy.create(upstream: "localhost:#{port}", name: "test_proxy")

      proxies = Toxiproxy.grep(/\Atest/)

      assert_equal 1, proxies.size
      assert_instance_of Toxiproxy::Collection, proxies
    end
  end

  def test_indexing_allows_regexp
    with_tcpserver do |port|
      Toxiproxy.create(upstream: "localhost:#{port}", name: "test_proxy")

      proxies = Toxiproxy[/\Atest/]

      assert_equal 1, proxies.size
      assert_instance_of Toxiproxy::Collection, proxies
    end
  end

  def test_apply_upstream_toxic
    with_tcpserver(receive: true) do |port|
      proxy = Toxiproxy.create(upstream: "localhost:#{port}", name: "test_proxy")

      proxy.upstream(:latency, latency: 100).apply do
        before = Time.now

        socket = connect_to_proxy(proxy)
        socket.write("omg\n")
        socket.flush
        socket.gets

        passed = Time.now - before

        assert_in_delta passed, 0.100, 0.01
      end
    end
  end

  def test_apply_downstream_toxic
    with_tcpserver(receive: true) do |port|
      proxy = Toxiproxy.create(upstream: "localhost:#{port}", name: "test_proxy")

      proxy.downstream(:latency, latency: 100).apply do
        before = Time.now

        socket = connect_to_proxy(proxy)
        socket.write("omg\n")
        socket.flush
        socket.gets

        passed = Time.now - before

        assert_in_delta passed, 0.100, 0.01
      end
    end
  end

  def test_apply_prolong_toxics
    with_tcpserver(receive: true) do |port|
      proxy = Toxiproxy.create(upstream: "localhost:#{port}", name: "test_proxy")

      proxy.upstream(:latency, latency: 100).downstream(:latency, latency: 100).apply do
        before = Time.now

        socket = connect_to_proxy(proxy)
        socket.write("omg\n")
        socket.flush
        socket.gets

        passed = Time.now - before

        assert_in_delta passed, 0.200, 0.01
      end
    end
  end

  def test_apply_toxics_to_collection
    with_tcpserver(receive: true) do |port1|
      with_tcpserver(receive: true) do |port2|
        proxy1 = Toxiproxy.create(upstream: "localhost:#{port1}", name: "test_proxy1")
        proxy2 = Toxiproxy.create(upstream: "localhost:#{port2}", name: "test_proxy2")

        Toxiproxy[/test_proxy/].upstream(:latency, latency: 100).downstream(:latency, latency: 100).apply do
          before = Time.now

          socket = connect_to_proxy(proxy1)
          socket.write("omg\n")
          socket.flush
          socket.gets

          passed = Time.now - before

          assert_in_delta passed, 0.200, 0.01

          before = Time.now

          socket = connect_to_proxy(proxy2)
          socket.write("omg\n")
          socket.flush
          socket.gets

          passed = Time.now - before

          assert_in_delta passed, 0.200, 0.01
        end
      end
    end
  end

  def test_populate_creates_proxies
    proxies = Toxiproxy.populate("./test/fixtures/toxiproxy.json")

    proxies.each do |proxy|
      assert_proxy_available(proxy)
    end
  end

  private

  def assert_proxy_available(proxy)
    connect_to_proxy proxy
  end

  def assert_proxy_unavailable(proxy)
    assert_raises Errno::ECONNREFUSED do
      connect_to_proxy proxy
    end
  end

  def connect_to_proxy(proxy)
    TCPSocket.new(*proxy.listen.split(":".freeze))
  end

  def with_tcpserver(receive = false, &block)
    mon = Monitor.new
    cond = mon.new_cond
    port = nil

    thread = Thread.new {
      server = TCPServer.new("127.0.0.1", 0)
      port = server.addr[1]
      mon.synchronize { cond.signal }
      loop do
        client = server.accept

        if receive
          client.gets
          client.write("omgs\n")
          client.flush
        end

        client.close
      end
      server.close
    }

    mon.synchronize { cond.wait }

    yield(port)
  ensure
    thread.kill
  end
end
