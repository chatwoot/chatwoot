# frozen_string_literal: true

module Twilio
  module REST
    class AuthType
      BASIC = 'basic'
      ORGS_TOKEN = 'orgs_token'
      API_KEY = 'api_key'
      NOAUTH = 'noauth'
      CLIENT_CREDENTIALS = 'client_credentials'

      def to_s
        name
      end
    end
  end
end
