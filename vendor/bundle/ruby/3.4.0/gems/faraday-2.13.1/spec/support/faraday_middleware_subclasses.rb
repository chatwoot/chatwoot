# frozen_string_literal: true

module FaradayMiddlewareSubclasses
  class SubclassNoOptions < Faraday::Middleware
  end

  class SubclassOneOption < Faraday::Middleware
    DEFAULT_OPTIONS = { some_other_option: false }.freeze
  end

  class SubclassTwoOptions < Faraday::Middleware
    DEFAULT_OPTIONS = { some_option: true, some_other_option: false }.freeze
  end
end

Faraday::Response.register_middleware(no_options: FaradayMiddlewareSubclasses::SubclassNoOptions)
Faraday::Response.register_middleware(one_option: FaradayMiddlewareSubclasses::SubclassOneOption)
Faraday::Response.register_middleware(two_options: FaradayMiddlewareSubclasses::SubclassTwoOptions)
