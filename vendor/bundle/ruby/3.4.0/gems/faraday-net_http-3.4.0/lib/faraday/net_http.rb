# frozen_string_literal: true

require 'faraday/adapter/net_http'
require 'faraday/net_http/version'

module Faraday
  module NetHttp
    Faraday::Adapter.register_middleware(net_http: Faraday::Adapter::NetHttp)
  end
end
