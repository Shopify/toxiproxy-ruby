class Toxiproxy
  class ToxicCollection
    extend Forwardable

    attr_accessor :toxics
    attr_reader :proxies

    def_delegators :@toxics, :<<, :find

    def initialize(proxies)
      @proxies = proxies
      @toxics = []
    end

    def apply(&block)
      @toxics.each(&:save)
      yield
    ensure
      @toxics.each(&:destroy)
    end

    def upstream(type, attrs = {})
      proxies.each do |proxy|
        toxics << Toxic.new(
          name: attrs.delete('name') || attrs.delete(:name),
          type: type,
          proxy: proxy,
          stream: :upstream,
          toxicity: attrs.delete('toxicitiy') || attrs.delete(:toxicity),
          attributes: attrs
        )
      end
      self
    end

    def downstream(type, attrs = {})
      proxies.each do |proxy|
        toxics << Toxic.new(
          name: attrs.delete('name') || attrs.delete(:name),
          type: type,
          proxy: proxy,
          stream: :downstream,
          toxicity: attrs.delete('toxicitiy') || attrs.delete(:toxicity),
          attributes: attrs
        )
      end
      self
    end
  end
end
