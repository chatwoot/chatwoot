# frozen_string_literal: true

require 'delegate'

module HTTParty
  # Allow access to http_response and code by delegation on fragment
  class ResponseFragment < SimpleDelegator
    attr_reader :http_response, :connection

    def code
      @http_response.code.to_i
    end

    def initialize(fragment, http_response, connection)
      @fragment = fragment
      @http_response = http_response
      @connection = connection
      super fragment
    end
  end
end
