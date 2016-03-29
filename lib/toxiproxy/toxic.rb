class Toxiproxy
  class Toxic
    attr_reader :name, :type, :attributes, :stream, :proxy
    attr_accessor :attributes, :toxicity

    def initialize(type:, name: nil, stream: 'downstream', toxicity: 1.0, proxy: nil, attributes: {})
      @name = name || "#{type}_#{stream}"
      @type = type
      @attributes = attributes
      @proxy = proxy
      @stream = stream
      @toxicity = toxicity
    end

    def save
      request = Net::HTTP::Post.new("/proxies/#{proxy.name}/toxics")

      request.body = as_json

      response = Toxiproxy.http.request(request)
      Toxiproxy.assert_response(response)

      json = JSON.parse(response.body)
      @attributes = json['attributes']
      @toxicity = json['toxicity']

      self
    end

    def destroy
      request = Net::HTTP::Delete.new("/proxies/#{proxy.name}/toxics/#{name}")
      response = Toxiproxy.http.request(request)
      Toxiproxy.assert_response(response)
      self
    end

    def as_json
      {
        name: name,
        type: type,
        stream: stream,
        toxicity: toxicity,
        attributes: attributes,
      }.to_json
    end
  end
end
