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
      @toxics.each(&:enable)
      yield
    ensure
      @toxics.each(&:disable)
    end

    def upstream(toxic_name, attrs = {})
      proxies.each do |proxy|
        toxics << Toxic.new(
          name: toxic_name,
          proxy: proxy,
          direction: :upstream,
          attrs: attrs
        )
      end
      self
    end

    def downstream(toxic_name, attrs = {})
      proxies.each do |proxy|
        toxics << Toxic.new(
          name: toxic_name,
          proxy: proxy,
          direction: :downstream,
          attrs: attrs
        )
      end
      self
    end
  end
end
