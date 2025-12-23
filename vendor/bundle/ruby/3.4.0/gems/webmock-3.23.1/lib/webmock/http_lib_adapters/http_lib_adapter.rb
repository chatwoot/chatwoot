# frozen_string_literal: true

module WebMock
  class HttpLibAdapter
    def self.adapter_for(lib)
      WebMock::HttpLibAdapterRegistry.instance.register(lib, self)
    end
  end
end