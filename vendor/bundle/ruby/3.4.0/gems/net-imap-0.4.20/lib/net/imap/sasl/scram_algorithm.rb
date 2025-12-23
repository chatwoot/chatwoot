# frozen_string_literal: true

module Net
  class IMAP
    module SASL

      # For method descriptions,
      # see {RFC5802 §2.2}[https://www.rfc-editor.org/rfc/rfc5802#section-2.2]
      # and {RFC5802 §3}[https://www.rfc-editor.org/rfc/rfc5802#section-3].
      module ScramAlgorithm
        def Normalize(str) SASL.saslprep(str) end

        def Hi(str, salt, iterations)
          length = digest.digest_length
          OpenSSL::KDF.pbkdf2_hmac(
            str,
            salt:       salt,
            iterations: iterations,
            length: length,
            hash: digest,
          )
        end

        def H(str) digest.digest str end

        def HMAC(key, data) OpenSSL::HMAC.digest(digest, key, data) end

        def XOR(str1, str2)
          str1.unpack("C*")
            .zip(str2.unpack("C*"))
            .map {|a, b| a ^ b }
            .pack("C*")
        end

        def auth_message
          [
            client_first_message_bare,
            server_first_message,
            client_final_message_without_proof,
          ]
            .join(",")
        end

        def salted_password
          Hi(Normalize(password), salt, iterations)
        end

        def client_key;       HMAC(salted_password, "Client Key") end
        def server_key;       HMAC(salted_password, "Server Key") end
        def stored_key;       H(client_key)                       end
        def client_signature; HMAC(stored_key, auth_message)      end
        def server_signature; HMAC(server_key, auth_message)      end
        def client_proof;     XOR(client_key, client_signature)   end
      end

    end
  end
end
