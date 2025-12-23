# frozen_string_literal: true

module Net
  class IMAP < Protocol
    module SASL

      # Authenticator for the "+ANONYMOUS+" SASL mechanism, as specified by
      # RFC-4505[https://tools.ietf.org/html/rfc4505].  See
      # Net::IMAP#authenticate.
      class AnonymousAuthenticator

        # An optional token sent for the +ANONYMOUS+ mechanism., up to 255 UTF-8
        # characters in length.
        #
        # If it contains an "@" sign, the message must be a valid email address
        # (+addr-spec+ from RFC-2822[https://tools.ietf.org/html/rfc2822]).
        # Email syntax is _not_ validated by AnonymousAuthenticator.
        #
        # Otherwise, it can be any UTF8 string which is permitted by the
        # StringPrep::Trace profile.
        attr_reader :anonymous_message

        # :call-seq:
        #   new(anonymous_message = "", **) -> authenticator
        #   new(anonymous_message:  "", **) -> authenticator
        #
        # Creates an Authenticator for the "+ANONYMOUS+" SASL mechanism, as
        # specified in RFC-4505[https://tools.ietf.org/html/rfc4505].  To use
        # this, see Net::IMAP#authenticate or your client's authentication
        # method.
        #
        # ==== Parameters
        #
        # * _optional_ #anonymous_message — a message to send to the server.
        #
        # Any other keyword arguments are silently ignored.
        def initialize(anon_msg = nil, anonymous_message: nil, **)
          message = (anonymous_message || anon_msg || "").to_str
          @anonymous_message = StringPrep::Trace.stringprep_trace message
          if (size = @anonymous_message&.length)&.> 255
            raise ArgumentError,
                  "anonymous_message is too long.  (%d codepoints)" % [size]
          end
          @done = false
        end

        # :call-seq:
        #   initial_response? -> true
        #
        # +ANONYMOUS+ can send an initial client response.
        def initial_response?; true end

        # Returns #anonymous_message.
        def process(_server_challenge_string)
          anonymous_message
        ensure
          @done = true
        end

        # Returns true when the initial client response was sent.
        #
        # The authentication should not succeed unless this returns true, but it
        # does *not* indicate success.
        def done?; @done end

      end
    end
  end
end
