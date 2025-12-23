# frozen_string_literal: true

class Redis
  # Base error for all redis-rb errors.
  class BaseError < StandardError
  end

  # Raised by the connection when a protocol error occurs.
  class ProtocolError < BaseError
    def initialize(reply_type)
      super(<<-EOS.gsub(/(?:^|\n)\s*/, " "))
        Got '#{reply_type}' as initial reply byte.
        If you're in a forking environment, such as Unicorn, you need to
        connect to Redis after forking.
      EOS
    end
  end

  # Raised by the client when command execution returns an error reply.
  class CommandError < BaseError
  end

  class PermissionError < CommandError
  end

  class WrongTypeError < CommandError
  end

  class OutOfMemoryError < CommandError
  end

  # Base error for connection related errors.
  class BaseConnectionError < BaseError
  end

  # Raised when connection to a Redis server cannot be made.
  class CannotConnectError < BaseConnectionError
  end

  # Raised when connection to a Redis server is lost.
  class ConnectionError < BaseConnectionError
  end

  # Raised when performing I/O times out.
  class TimeoutError < BaseConnectionError
  end

  # Raised when the connection was inherited by a child process.
  class InheritedError < BaseConnectionError
  end

  # Generally raised during Redis failover scenarios
  class ReadOnlyError < BaseConnectionError
  end

  # Raised when client options are invalid.
  class InvalidClientOptionError < BaseError
  end

  class SubscriptionError < BaseError
  end
end
