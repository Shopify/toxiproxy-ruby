require "json"
require "uri"
require "net/http"
require "forwardable"

class Toxiproxy
  URI = ::URI.parse("http://127.0.0.1:8474")
  VALID_DIRECTIONS = [:upstream, :downstream]

  class NotFound < StandardError; end
  class ProxyExists < StandardError; end
  class InvalidToxic < StandardError; end

  # ProxyCollection represents a set of proxies. This allows to easily perform
  # actions on every proxy in the collection.
  #
  # Unfortunately, it doesn't implement all of Enumerable because there's no way
  # to subclass an Array or include Enumerable for the methods to return a
  # Collection instead of an Array (see MRI). Instead, we delegate methods where
  # it doesn't matter and only allow the filtering methods that really make
  # sense on a proxy collection.
  class Collection
    extend Forwardable

    DELEGATED_METHODS = [:length, :size, :count, :find, :each, :map]
    DEFINED_METHODS   = [:select, :reject, :grep, :down]
    METHODS = DEFINED_METHODS + DELEGATED_METHODS

    def_delegators :@collection, *DELEGATED_METHODS

    def initialize(collection)
      @collection = collection
    end

    # Sets every proxy in the collection as down. For example:
    #
    #   Toxiproxy.grep(/redis/).down { .. }
    #
    # Would simulate every Redis server being down for the duration of the
    # block.
    def down(*args, &block)
      @collection.inject(block) { |nested, proxy|
        -> { proxy.down(*args, &nested) }
      }.call
    end

    # Destroys all toxiproxy's in the collection
    def destroy
      @collection.each(&:destroy)
    end

    def select(&block)
      self.class.new(@collection.select(&block))
    end

    def reject(&block)
      self.class.new(@collection.reject(&block))
    end

    # Grep allows easily selecting a subset of proxies, by returning a
    # ProxyCollection with every proxy name matching the regex passed.
    def grep(regex)
      self.class.new(@collection.select { |proxy|
        proxy.name =~ regex
      })
    end
  end

  class Toxic
    attr_reader :name, :proxy, :direction
    attr_reader :attrs

    def initialize(proxy:, name:, direction:, attrs: {})
      @proxy     = proxy
      @name      = name
      @direction = direction
      @attrs     = attrs
    end

    def enabled?
      attrs[:enabled]
    end

    def enable
      attrs[:enabled] = true
      save
    end

    def disable
      attrs[:enabled] = false
      save
    end

    def []=(name, value)
      attrs[name] = value
    end

    def save
      unless VALID_DIRECTIONS.include?(direction.to_sym)
        raise InvalidToxic, "Toxic direction must be one of: [#{VALID_DIRECTIONS.join(', ')}], got: #{direction}"
      end
      request = Net::HTTP::Post.new("/proxies/#{proxy.name}/#{direction}/toxics/#{name}")

      request.body = attrs.to_json

      response = Toxiproxy.http.request(request)
      assert_response(response)

      @attrs = JSON.parse(response.body)

      self
    end
  end

  attr_reader :listen, :name

  def initialize(upstream:, name:, listen: "localhost:0")
    @upstream = upstream
    @listen   = listen
    @name     = name
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

  # Returns a collection of all currently active Toxiproxies.
  def self.all
    request = Net::HTTP::Get.new("/proxies")
    response = http.request(request)
    assert_response(response)

    proxies = JSON.parse(response.body).map { |name, attrs|
      self.new({
        upstream: attrs["upstream"],
        listen: attrs["listen"],
        name: attrs["name"]
      })
    }

    Collection.new(proxies)
  end

  # Convenience method to create a proxy.
  def self.create(**args)
    self.new(**args).create
  end

  # Find a single proxy by name.
  def self.find_by_name(name = nil, &block)
    proxy = self.all.find { |p| p.name == name.to_s }
    raise NotFound, "#{name} not found in #{self.all.map(&:name).join(', ')}" unless proxy
    proxy
  end

  # If given a regex, it'll use `grep` to return a Toxiproxy::Collection.
  # Otherwise, it'll convert the passed object to a string and find the proxy by
  # name.
  def self.[](query)
    return grep(query) if query.is_a?(Regexp)
    find_by_name(query)
  end

  class ToxicCollection
    extend Forwardable

    attr_accessor :toxics
    attr_reader :proxy

    def_delegators :@toxics, :<<, :find

    def initialize(proxy)
      @proxy  = proxy
      @toxics = []
    end

    def apply(&block)
      @toxics.each(&:enable)
      yield
    ensure
      @toxics.each(&:disable)
    end

    def upstream(toxic_name, attrs = {})
      toxics << Toxic.new(
        name: toxic_name,
        proxy: proxy,
        direction: :upstream,
        attrs: attrs
      )
      self
    end

    def downstream(toxic_name, attrs = {})
      toxics << Toxic.new(
        name: toxic_name,
        proxy: proxy,
        direction: :downstream,
        attrs: attrs
      )
      self
    end
  end

  def upstream(toxic = nil, attrs = {})
    return @upstream unless toxic

    collection = ToxicCollection.new(self)
    collection.upstream(toxic, attrs)
    collection
  end

  def downstream(toxic, attrs = {})
    collection = ToxicCollection.new(self)
    collection.downstream(toxic, attrs)
    collection
  end

  # Simulates the endpoint is down, by closing the connection and no
  # longer accepting connections. This is useful to simulate critical system
  # failure, such as a data store becoming completely unavailable.
  def down(&block)
    uptoxics = toxics(:upstream)
    downtoxics = toxics(:downstream)
    destroy
    begin
      yield
    ensure
      create
      uptoxics.each(&:save)
      downtoxics.each(&:save)
    end
  end

  # Create a Toxiproxy, proxying traffic from `@listen` (optional argument to
  # the constructor) to `@upstream`. `#down` `#upstream` or `#downstream` can at any time alter the health
  # of this connection.
  def create
    request = Net::HTTP::Post.new("/proxies")

    hash = {upstream: upstream, name: name, listen: listen}
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

  private

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

  def self.http
    @http ||= Net::HTTP.new(URI.host, URI.port)
  end

  def http
    self.class.http
  end
end

def assert_response(response)
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
