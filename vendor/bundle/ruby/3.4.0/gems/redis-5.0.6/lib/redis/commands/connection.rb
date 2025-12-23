# frozen_string_literal: true

class Redis
  module Commands
    module Connection
      # Authenticate to the server.
      #
      # @param [Array<String>] args includes both username and password
      #   or only password
      # @return [String] `OK`
      # @see https://redis.io/commands/auth AUTH command
      def auth(*args)
        send_command([:auth, *args])
      end

      # Ping the server.
      #
      # @param [optional, String] message
      # @return [String] `PONG`
      def ping(message = nil)
        send_command([:ping, message].compact)
      end

      # Echo the given string.
      #
      # @param [String] value
      # @return [String]
      def echo(value)
        send_command([:echo, value])
      end

      # Change the selected database for the current connection.
      #
      # @param [Integer] db zero-based index of the DB to use (0 to 15)
      # @return [String] `OK`
      def select(db)
        send_command([:select, db])
      end

      # Close the connection.
      #
      # @return [String] `OK`
      def quit
        synchronize do |client|
          client.call_v([:quit])
        rescue ConnectionError
        ensure
          client.close
        end
      end
    end
  end
end
