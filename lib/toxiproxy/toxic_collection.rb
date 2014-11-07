class Toxiproxy
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
end
