module Twilio
  module REST
    class AuthStrategy
      attr_accessor :auth_type

      def initialize(auth_type)
        @auth_type = auth_type
      end

      def auth_string
        raise NotImplementedError, 'Subclasses must implement this method'
      end

      def requires_authentication
        raise NotImplementedError, 'Subclasses must implement this method'
      end
    end
  end
end
