# frozen_string_literal: true

module Net
  class IMAP
    module SASL

      # This API is *experimental*, and may change.
      #
      # TODO: use with more clients, to verify the API can accommodate them.
      #
      # An abstract base class for implementing a SASL authentication exchange.
      # Different clients will each have their own adapter subclass, overridden
      # to match their needs.
      #
      # Although the default implementations _may_ be sufficient, subclasses
      # will probably need to override some methods.  Additionally, subclasses
      # may need to include a protocol adapter mixin, if the default
      # ProtocolAdapters::Generic isn't sufficient.
      class ClientAdapter
        include ProtocolAdapters::Generic

        attr_reader :client, :command_proc

        # +command_proc+ can used to avoid exposing private methods on #client.
        # It should run a command with the arguments sent to it, yield each
        # continuation payload, respond to the server with the result of each
        # yield, and return the result.  Non-successful results *MUST* raise an
        # exception.  Exceptions in the block *MUST* cause the command to fail.
        #
        # Subclasses that override #run_command may use #command_proc for
        # other purposes.
        def initialize(client, &command_proc)
          @client, @command_proc = client, command_proc
        end

        # Delegates to AuthenticationExchange.authenticate.
        def authenticate(...) AuthenticationExchange.authenticate(self, ...) end

        # Do the protocol and server both support an initial response?
        def sasl_ir_capable?; client.sasl_ir_capable? end

        # Does the server advertise support for the mechanism?
        def auth_capable?(mechanism); client.auth_capable?(mechanism) end

        # Runs the authenticate command with +mechanism+ and +initial_response+.
        # When +initial_response+ is nil, an initial response must NOT be sent.
        #
        # Yields each continuation payload, responds to the server with the
        # result of each yield, and returns the result.  Non-successful results
        # *MUST* raise an exception.  Exceptions in the block *MUST* cause the
        # command to fail.
        #
        # Subclasses that override this may use #command_proc differently.
        def run_command(mechanism, initial_response = nil, &block)
          command_proc or raise Error, "initialize with block or override"
          args = [command_name, mechanism, initial_response].compact
          command_proc.call(*args, &block)
        end

        # Returns an array of server responses errors raised by run_command.
        # Exceptions in this array won't drop the connection.
        def response_errors; [] end

        # Drop the connection gracefully.
        def drop_connection;  client.drop_connection end

        # Drop the connection abruptly.
        def drop_connection!; client.drop_connection! end
      end
    end
  end
end
