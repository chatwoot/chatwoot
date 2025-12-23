# frozen_string_literal: true

module Net
  class IMAP
    module SASL

      module ProtocolAdapters
        # This API is experimental, and may change.
        module Generic
          def command_name;     "AUTHENTICATE" end
          def service;          raise "Implement in subclass or module" end
          def host;             client.host end
          def port;             client.port end
          def encode_ir(string) string.empty? ? "=" : encode(string) end
          def encode(string)    [string].pack("m0") end
          def decode(string)    string.unpack1("m0") end
          def cancel_response;  "*" end
        end

        # See RFC-3501 (IMAP4rev1), RFC-4959 (SASL-IR capability),
        # and RFC-9051 (IMAP4rev2).
        module IMAP
          include Generic
          def service; "imap" end
        end

        # See RFC-4954 (AUTH capability).
        module SMTP
          include Generic
          def command_name; "AUTH" end
          def service; "smtp" end
        end

        # See RFC-5034 (SASL capability).
        module POP
          include Generic
          def command_name; "AUTH" end
          def service; "pop" end
        end

      end

    end
  end
end
