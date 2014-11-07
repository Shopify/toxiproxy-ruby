class Toxiproxy
  class Toxic
    attr_reader :name, :proxy, :direction
    attr_reader :attrs

    def initialize(options)
      @proxy     = options[:proxy]
      @name      = options[:name]
      @direction = options[:direction]
      @attrs     = options[:attrs] || {}
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
      Toxiproxy.assert_response(response)

      @attrs = JSON.parse(response.body)

      self
    end
  end
end
