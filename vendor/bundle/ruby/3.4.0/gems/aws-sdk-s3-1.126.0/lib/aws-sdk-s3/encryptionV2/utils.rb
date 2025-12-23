# frozen_string_literal: true

require 'openssl'

module Aws
  module S3
    module EncryptionV2
      # @api private
      module Utils

        class << self

          def encrypt_aes_gcm(key, data, auth_data)
            cipher = aes_encryption_cipher(:GCM, key)
            cipher.iv = (iv = cipher.random_iv)
            cipher.auth_data = auth_data

            iv + cipher.update(data) + cipher.final + cipher.auth_tag
          end

          def encrypt_rsa(key, data, auth_data)
            # Plaintext must be KeyLengthInBytes (1 Byte) + DataKey + AuthData
            buf = [data.bytesize] + data.unpack('C*') + auth_data.unpack('C*')
            key.public_encrypt(buf.pack('C*'), OpenSSL::PKey::RSA::PKCS1_OAEP_PADDING)
          end

          def decrypt(key, data)
            begin
              case key
              when OpenSSL::PKey::RSA # asymmetric decryption
                key.private_decrypt(data)
              when String # symmetric Decryption
                cipher = aes_cipher(:decrypt, :ECB, key, nil)
                cipher.update(data) + cipher.final
              end
            rescue OpenSSL::Cipher::CipherError
              msg = 'decryption failed, possible incorrect key'
              raise Errors::DecryptionError, msg
            end
          end

          def decrypt_aes_gcm(key, data, auth_data)
            # data is iv (12B) + key + tag (16B)
            buf = data.unpack('C*')
            iv = buf[0,12].pack('C*') # iv will always be 12 bytes
            tag = buf[-16, 16].pack('C*') # tag is 16 bytes
            enc_key = buf[12, buf.size - (12+16)].pack('C*')
            cipher = aes_cipher(:decrypt, :GCM, key, iv)
            cipher.auth_tag = tag
            cipher.auth_data = auth_data
            cipher.update(enc_key) + cipher.final
          end

          # returns the decrypted data + auth_data
          def decrypt_rsa(key, enc_data)
            # Plaintext must be KeyLengthInBytes (1 Byte) + DataKey + AuthData
            buf = key.private_decrypt(enc_data, OpenSSL::PKey::RSA::PKCS1_OAEP_PADDING).unpack('C*')
            key_length = buf[0]
            data = buf[1, key_length].pack('C*')
            auth_data = buf[key_length+1, buf.length - key_length].pack('C*')
            [data, auth_data]
          end

          # @param [String] block_mode "CBC" or "ECB"
          # @param [OpenSSL::PKey::RSA, String, nil] key
          # @param [String, nil] iv The initialization vector
          def aes_encryption_cipher(block_mode, key = nil, iv = nil)
            aes_cipher(:encrypt, block_mode, key, iv)
          end

          # @param [String] block_mode "CBC" or "ECB"
          # @param [OpenSSL::PKey::RSA, String, nil] key
          # @param [String, nil] iv The initialization vector
          def aes_decryption_cipher(block_mode, key = nil, iv = nil)
            aes_cipher(:decrypt, block_mode, key, iv)
          end

          # @param [String] mode "encrypt" or "decrypt"
          # @param [String] block_mode "CBC" or "ECB"
          # @param [OpenSSL::PKey::RSA, String, nil] key
          # @param [String, nil] iv The initialization vector
          def aes_cipher(mode, block_mode, key, iv)
            cipher = key ?
              OpenSSL::Cipher.new("aes-#{cipher_size(key)}-#{block_mode.downcase}") :
              OpenSSL::Cipher.new("aes-256-#{block_mode.downcase}")
            cipher.send(mode) # encrypt or decrypt
            cipher.key = key if key
            cipher.iv = iv if iv
            cipher
          end

          # @param [String] key
          # @return [Integer]
          # @raise ArgumentError
          def cipher_size(key)
            key.bytesize * 8
          end

        end
      end
    end
  end
end
