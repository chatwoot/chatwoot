# frozen_string_literal: true

require "action_controller"
require "action_controller/test_process"

module OAuth
  module OAuthTestHelper
    def mock_incoming_request_with_query(request)
      incoming = ActionController::TestRequest.new(request.to_hash)
      incoming.request_uri = request.path
      incoming.host = request.uri.host
      incoming.env["SERVER_PORT"] = request.uri.port
      incoming.env["REQUEST_METHOD"] = request.http_method
      incoming
    end

    def mock_incoming_request_with_authorize_header(request)
      incoming = ActionController::TestRequest.new
      incoming.request_uri = request.path
      incoming.host = request.uri.host
      incoming.env["HTTP_AUTHORIZATION"] = request.to_auth_string
      incoming.env["SERVER_PORT"] = request.uri.port
      incoming.env["REQUEST_METHOD"] = request.http_method
      incoming
    end
  end
end
