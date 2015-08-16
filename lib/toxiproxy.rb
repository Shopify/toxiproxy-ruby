require "json"
require "uri"
require "net/http"

require "toxiproxy/collection"
require "toxiproxy/toxic"
require "toxiproxy/toxic_collection"

class Toxiproxy
  URI = ::URI.parse("http://127.0.0.1:8474")
  VALID_DIRECTIONS = [:upstream, :downstream]

  class NotFound < StandardError; end
  class ProxyExists < StandardError; end
  class InvalidToxic < StandardError; end

  attr_reader :listen, :name, :enabled

  def initialize(options)
    @upstream = options[:upstream]
    @listen   = options[:listen] || "localhost:0"
    @name     = options[:name]
    @enabled  = options[:enabled]
  end

  # Forwardable doesn't support delegating class methods, so we resort to
  # `define_method` to delegate from Toxiproxy to #all, and from there to the
  # proxy collection.
  class << self
    Collection::METHODS.each do |method|
      define_method(method) do |*args, &block|
        self.all.send(method, *args, &block)
      end
    end
  end

  # Re-enables all proxies and disables all toxics.
  def self.reset
    request = Net::HTTP::Get.new("/reset")
    response = http.request(request)
    assert_response(response)
    self
  end

  # Returns a collection of all currently active Toxiproxies.
  def self.all
    request = Net::HTTP::Get.new("/proxies")
    response = http.request(request)
    assert_response(response)

    proxies = JSON.parse(response.body).map { |name, attrs|
      self.new({
        upstream: attrs["upstream"],
        listen: attrs["listen"],
        name: attrs["name"],
        enabled: attrs["enabled"]
      })
    }

    Collection.new(proxies)
  end

  # Convenience method to create a proxy.
  def self.create(options)
    self.new(options).create
  end

  # Find a single proxy by name.
  def self.find_by_name(name = nil, &block)
    self.all.find { |p| p.name == name.to_s }
  end

  # Calls find_by_name and raises NotFound if not found
  def self.find_by_name!(*args)
    proxy = find_by_name(*args)
    raise NotFound, "#{name} not found in #{self.all.map(&:name).join(', ')}" unless proxy
    proxy
  end

  # If given a regex, it'll use `grep` to return a Toxiproxy::Collection.
  # Otherwise, it'll convert the passed object to a string and find the proxy by
  # name.
  def self.[](query)
    return grep(query) if query.is_a?(Regexp)
    find_by_name!(query)
  end

  def self.populate(*proxies)
    proxies = proxies.first if proxies.first.is_a?(Array)

    proxies.map { |proxy|
      existing = find_by_name(proxy[:name])
      if existing && (existing.upstream != proxy[:upstream] || existing.listen != proxy[:listen])
        existing.destroy
        existing = false
      end
      self.create(proxy) unless existing
    }.compact
  end

  def self.running?
    TCPSocket.new(URI.host, URI.port).close
    true
  rescue Errno::ECONNREFUSED, Errno::ECONNRESET
    false
  end

  # Set an upstream toxic.
  def upstream(toxic = nil, attrs = {})
    return @upstream unless toxic

    collection = ToxicCollection.new([self])
    collection.upstream(toxic, attrs)
    collection
  end

  # Set a downstream toxic.
  def downstream(toxic, attrs = {})
    collection = ToxicCollection.new([self])
    collection.downstream(toxic, attrs)
    collection
  end

  # Simulates the endpoint is down, by closing the connection and no
  # longer accepting connections. This is useful to simulate critical system
  # failure, such as a data store becoming completely unavailable.
  def down(&block)
    disable
    yield
  ensure
    enable
  end

  # Disables a Toxiproxy. This will drop all active connections and stop the proxy from listening.
  def disable
    request = Net::HTTP::Post.new("/proxies/#{name}")

    hash = {enabled: false}
    request.body = hash.to_json

    response = http.request(request)
    assert_response(response)
    self
  end

  # Enables a Toxiproxy. This will cause the proxy to start listening again.
  def enable
    request = Net::HTTP::Post.new("/proxies/#{name}")

    hash = {enabled: true}
    request.body = hash.to_json

    response = http.request(request)
    assert_response(response)
    self
  end

  # Create a Toxiproxy, proxying traffic from `@listen` (optional argument to
  # the constructor) to `@upstream`. `#down` `#upstream` or `#downstream` can at any time alter the health
  # of this connection.
  def create
    request = Net::HTTP::Post.new("/proxies")

    hash = {upstream: upstream, name: name, listen: listen, enabled: enabled}
    request.body = hash.to_json

    response = http.request(request)
    assert_response(response)

    new = JSON.parse(response.body)
    @listen = new["listen"]

    self
  end

  # Destroys a Toxiproxy.
  def destroy
    request = Net::HTTP::Delete.new("/proxies/#{name}")
    response = http.request(request)
    assert_response(response)
    self
  end

  # Returns a collection of the current toxics for a direction.
  def toxics(direction)
    unless VALID_DIRECTIONS.include?(direction.to_sym)
      raise InvalidToxic, "Toxic direction must be one of: [#{VALID_DIRECTIONS.join(', ')}], got: #{direction}"
    end

    request = Net::HTTP::Get.new("/proxies/#{name}/#{direction}/toxics")
    response = http.request(request)
    assert_response(response)

    toxics = JSON.parse(response.body).map { |name, attrs|
      Toxic.new({
        name: name,
        proxy: self,
        direction: direction,
        attrs: attrs
      })
    }

    toxics
  end

  private

  def self.http
    @http ||= Net::HTTP.new(URI.host, URI.port)
  end

  def http
    self.class.http
  end

  def self.assert_response(response)
    case response
    when Net::HTTPConflict
      raise Toxiproxy::ProxyExists, response.body
    when Net::HTTPNotFound
      raise Toxiproxy::NotFound, response.body
    when Net::HTTPBadRequest
      raise Toxiproxy::InvalidToxic, response.body
    else
      response.value # raises if not OK
    end
  end

  def assert_response(*args)
    self.class.assert_response(*args)
  end
end
