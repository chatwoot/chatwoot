module Twilio
  module REST
    class NoAuthStrategy < AuthStrategy
      def initialize
        super(AuthType::NONE)
      end

      def auth_string
        ''
      end

      def requires_authentication
        false
      end
    end
  end
end
