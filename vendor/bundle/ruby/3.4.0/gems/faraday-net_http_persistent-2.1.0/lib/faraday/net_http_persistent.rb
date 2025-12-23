# frozen_string_literal: true

require "faraday"
require "faraday/adapter/net_http_persistent"
require "faraday/net_http_persistent/version"

module Faraday
  module NetHttpPersistent
    # Faraday allows you to register your middleware for easier configuration.
    # This step is totally optional, but it basically allows users to use a custom symbol (in this case, `:net_http_persistent`),
    # to use your adapter in their connections.
    # After calling this line, the following are both valid ways to set the adapter in a connection:
    # * conn.adapter Faraday::Adapter::NetNttpPersistent
    # * conn.adapter :net_http_persistent
    # Without this line, only the former method is valid.
    Faraday::Adapter.register_middleware(net_http_persistent: Faraday::Adapter::NetHttpPersistent)
  end
end
