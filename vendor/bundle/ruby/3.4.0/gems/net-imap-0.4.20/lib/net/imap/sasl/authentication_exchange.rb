# frozen_string_literal: true

module Net
  class IMAP
    module SASL

      # This API is *experimental*, and may change.
      #
      # TODO: catch exceptions in #process and send #cancel_response.
      # TODO: raise an error if the command succeeds after being canceled.
      # TODO: use with more clients, to verify the API can accommodate them.
      #
      # Create an AuthenticationExchange from a client adapter and a mechanism
      # authenticator:
      #     def authenticate(mechanism, ...)
      #       authenticator = SASL.authenticator(mechanism, ...)
      #       SASL::AuthenticationExchange.new(
      #         sasl_adapter, mechanism, authenticator
      #       ).authenticate
      #     end
      #
      #     private
      #
      #     def sasl_adapter = MyClientAdapter.new(self, &method(:send_command))
      #
      # Or delegate creation of the authenticator to ::build:
      #     def authenticate(...)
      #       SASL::AuthenticationExchange.build(sasl_adapter, ...)
      #         .authenticate
      #     end
      #
      # As a convenience, ::authenticate combines ::build and #authenticate:
      #     def authenticate(...)
      #       SASL::AuthenticationExchange.authenticate(sasl_adapter, ...)
      #     end
      #
      # Likewise, ClientAdapter#authenticate delegates to #authenticate:
      #     def authenticate(...) = sasl_adapter.authenticate(...)
      #
      class AuthenticationExchange
        # Convenience method for <tt>build(...).authenticate</tt>
        def self.authenticate(...) build(...).authenticate end

        # Use +registry+ to override the global Authenticators registry.
        def self.build(client, mechanism, *args, sasl_ir: true, **kwargs, &block)
          authenticator = SASL.authenticator(mechanism, *args, **kwargs, &block)
          new(client, mechanism, authenticator, sasl_ir: sasl_ir)
        end

        attr_reader :mechanism, :authenticator

        def initialize(client, mechanism, authenticator, sasl_ir: true)
          @client = client
          @mechanism = -mechanism.to_s.upcase.tr(?_, ?-)
          @authenticator = authenticator
          @sasl_ir = sasl_ir
          @processed = false
        end

        # Call #authenticate to execute an authentication exchange for #client
        # using #authenticator.  Authentication failures will raise an
        # exception.  Any exceptions other than those in RESPONSE_ERRORS will
        # drop the connection.
        def authenticate
          client.run_command(mechanism, initial_response) { process _1 }
            .tap { raise AuthenticationIncomplete, _1 unless done? }
        rescue *client.response_errors
          raise # but don't drop the connection
        rescue
          client.drop_connection
          raise
        rescue Exception # rubocop:disable Lint/RescueException
          client.drop_connection!
          raise
        end

        def send_initial_response?
          @sasl_ir &&
            authenticator.respond_to?(:initial_response?) &&
            authenticator.initial_response? &&
            client.sasl_ir_capable? &&
            client.auth_capable?(mechanism)
        end

        def done?
          authenticator.respond_to?(:done?) ? authenticator.done? : @processed
        end

        private

        attr_reader :client

        def initial_response
          return unless send_initial_response?
          client.encode_ir authenticator.process nil
        end

        def process(challenge)
          client.encode authenticator.process client.decode challenge
        ensure
          @processed = true
        end

      end
    end
  end
end
