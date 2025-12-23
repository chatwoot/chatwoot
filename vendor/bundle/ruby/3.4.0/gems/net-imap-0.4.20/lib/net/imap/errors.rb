# frozen_string_literal: true

module Net
  class IMAP < Protocol

    # Superclass of IMAP errors.
    class Error < StandardError
    end

    # Error raised when data is in the incorrect format.
    class DataFormatError < Error
    end

    # Error raised when the socket cannot be read, due to a Config limit.
    class ResponseReadError < Error
    end

    # Error raised when a response is larger than IMAP#max_response_size.
    class ResponseTooLargeError < ResponseReadError
      attr_reader :bytes_read, :literal_size
      attr_reader :max_response_size

      def initialize(msg = nil, *args,
                     bytes_read:        nil,
                     literal_size:      nil,
                     max_response_size: nil,
                     **kwargs)
        @bytes_read        = bytes_read
        @literal_size      = literal_size
        @max_response_size = max_response_size
        msg ||= [
          "Response size", response_size_msg, "exceeds max_response_size",
          max_response_size && "(#{max_response_size}B)",
        ].compact.join(" ")
        super(msg, *args, **kwargs)
      end

      private

      def response_size_msg
        if bytes_read && literal_size
          "(#{bytes_read}B read + #{literal_size}B literal)"
        end
      end
    end

    # Error raised when a response from the server is non-parsable.
    class ResponseParseError < Error
    end

    # Superclass of all errors used to encapsulate "fail" responses
    # from the server.
    class ResponseError < Error

      # The response that caused this error
      attr_accessor :response

      def initialize(response)
        @response = response

        super @response.data.text
      end

    end

    # Error raised upon a "NO" response from the server, indicating
    # that the client command could not be completed successfully.
    class NoResponseError < ResponseError
    end

    # Error raised upon a "BAD" response from the server, indicating
    # that the client command violated the IMAP protocol, or an internal
    # server failure has occurred.
    class BadResponseError < ResponseError
    end

    # Error raised upon a "BYE" response from the server, indicating
    # that the client is not being allowed to login, or has been timed
    # out due to inactivity.
    class ByeResponseError < ResponseError
    end

    # Error raised when the server sends an invalid response.
    #
    # This is different from UnknownResponseError: the response has been
    # rejected.  Although it may be parsable, the server is forbidden from
    # sending it in the current context.  The client should automatically
    # disconnect, abruptly (without logout).
    #
    # Note that InvalidResponseError does not inherit from ResponseError: it
    # can be raised before the response is fully parsed.  A related
    # ResponseParseError or ResponseError may be the #cause.
    class InvalidResponseError < Error
    end

    # Error raised upon an unknown response from the server.
    #
    # This is different from InvalidResponseError: the response may be a
    # valid extension response and the server may be allowed to send it in
    # this context, but Net::IMAP either does not know how to parse it or
    # how to handle it.  This could result from enabling unknown or
    # unhandled extensions.  The connection may still be usable,
    # but—depending on context—it may be prudent to disconnect.
    class UnknownResponseError < ResponseError
    end

    RESPONSE_ERRORS = Hash.new(ResponseError) # :nodoc:
    RESPONSE_ERRORS["NO"] = NoResponseError
    RESPONSE_ERRORS["BAD"] = BadResponseError

  end
end
