# frozen_string_literal: true

module Net
  class IMAP

    # Experimental
    class SASLAdapter < SASL::ClientAdapter
      include SASL::ProtocolAdapters::IMAP

      RESPONSE_ERRORS = [NoResponseError, BadResponseError, ByeResponseError]
        .freeze

      def response_errors;          RESPONSE_ERRORS                 end
      def sasl_ir_capable?;         client.capable?("SASL-IR")      end
      def auth_capable?(mechanism); client.auth_capable?(mechanism) end
      def drop_connection;          client.logout!                  end
      def drop_connection!;         client.disconnect               end
    end

  end
end
