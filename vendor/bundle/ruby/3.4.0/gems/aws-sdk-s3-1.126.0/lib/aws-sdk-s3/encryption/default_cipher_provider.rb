# frozen_string_literal: true

require 'base64'

module Aws
  module S3
    module Encryption
      # @api private
      class DefaultCipherProvider

        def initialize(options = {})
          @key_provider = options[:key_provider]
        end

        # @return [Array<Hash,Cipher>] Creates an returns a new encryption
        #   envelope and encryption cipher.
        def encryption_cipher
          cipher = Utils.aes_encryption_cipher(:CBC)
          envelope = {
            'x-amz-key' => encode64(encrypt(envelope_key(cipher))),
            'x-amz-iv' => encode64(envelope_iv(cipher)),
            'x-amz-matdesc' => materials_description,
          }
          [envelope, cipher]
        end

        # @return [Cipher] Given an encryption envelope, returns a
        #   decryption cipher.
        def decryption_cipher(envelope, options = {})
          master_key = @key_provider.key_for(envelope['x-amz-matdesc'])
          if envelope.key? 'x-amz-key'
            # Support for decryption of legacy objects
            key = Utils.decrypt(master_key, decode64(envelope['x-amz-key']))
            iv = decode64(envelope['x-amz-iv'])
            Utils.aes_decryption_cipher(:CBC, key, iv)
          else
            if envelope['x-amz-cek-alg'] != 'AES/GCM/NoPadding'
              raise ArgumentError, 'Unsupported cek-alg: ' \
                "#{envelope['x-amz-cek-alg']}"
            end
            key =
              case envelope['x-amz-wrap-alg']
              when 'AES/GCM'
                if master_key.is_a? OpenSSL::PKey::RSA
                  raise ArgumentError, 'Key mismatch - Client is configured' \
                    ' with an RSA key and the x-amz-wrap-alg is AES/GCM.'
                end
                Utils.decrypt_aes_gcm(master_key,
                                      decode64(envelope['x-amz-key-v2']),
                                      envelope['x-amz-cek-alg'])
              when 'RSA-OAEP-SHA1'
                unless master_key.is_a? OpenSSL::PKey::RSA
                  raise ArgumentError, 'Key mismatch - Client is configured' \
                    ' with an AES key and the x-amz-wrap-alg is RSA-OAEP-SHA1.'
                end
                key, cek_alg = Utils.decrypt_rsa(master_key, decode64(envelope['x-amz-key-v2']))
                raise Errors::DecryptionError unless cek_alg == envelope['x-amz-cek-alg']
                key
              when 'kms+context'
                raise ArgumentError, 'Key mismatch - Client is configured' \
                    ' with a user provided key and the x-amz-wrap-alg is' \
                    ' kms+context.  Please configure the client with the' \
                    ' required kms_key_id'
              else
                raise ArgumentError, 'Unsupported wrap-alg: ' \
                "#{envelope['x-amz-wrap-alg']}"
              end
            iv = decode64(envelope['x-amz-iv'])
            Utils.aes_decryption_cipher(:GCM, key, iv)
          end
        end

        private

        def envelope_key(cipher)
          cipher.key = cipher.random_key
        end

        def envelope_iv(cipher)
          cipher.iv = cipher.random_iv
        end

        def encrypt(data)
          Utils.encrypt(@key_provider.encryption_materials.key, data)
        end

        def materials_description
          @key_provider.encryption_materials.description
        end

        def encode64(str)
          Base64.encode64(str).split("\n") * ""
        end

        def decode64(str)
          Base64.decode64(str)
        end
      end
    end
  end
end
