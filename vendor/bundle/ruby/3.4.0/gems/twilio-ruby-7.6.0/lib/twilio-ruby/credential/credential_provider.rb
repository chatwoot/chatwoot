module Twilio
  module REST
    class CredentialProvider
      attr_accessor :auth_type

      def initialize(auth_type)
        @auth_type = auth_type
      end
    end
  end
end
