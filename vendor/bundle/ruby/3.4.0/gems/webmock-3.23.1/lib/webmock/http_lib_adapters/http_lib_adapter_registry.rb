# frozen_string_literal: true

module WebMock
  class HttpLibAdapterRegistry
    include Singleton

    attr_accessor :http_lib_adapters

    def initialize
      @http_lib_adapters = {}
    end

    def register(lib, adapter)
      @http_lib_adapters[lib] = adapter
    end

    def each_adapter(&block)
      @http_lib_adapters.each(&block)
    end
  end
end