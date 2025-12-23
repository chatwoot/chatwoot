# frozen_string_literal: true

require 'base64'

module Aws
  module S3
    module Encryption
      # @api private
      class KmsCipherProvider

        def initialize(options = {})
          @kms_key_id = options[:kms_key_id]
          @kms_client = options[:kms_client]
        end

        # @return [Array<Hash,Cipher>] Creates an returns a new encryption
        #   envelope and encryption cipher.
        def encryption_cipher
          encryption_context = { "kms_cmk_id" => @kms_key_id }
          key_data = Aws::Plugins::UserAgent.feature('S3CryptoV1n') do
            @kms_client.generate_data_key(
              key_id: @kms_key_id,
              encryption_context: encryption_context,
              key_spec: 'AES_256'
            )
          end
          cipher = Utils.aes_encryption_cipher(:CBC)
          cipher.key = key_data.plaintext
          envelope = {
            'x-amz-key-v2' => encode64(key_data.ciphertext_blob),
            'x-amz-iv' => encode64(cipher.iv = cipher.random_iv),
            'x-amz-cek-alg' => 'AES/CBC/PKCS5Padding',
            'x-amz-wrap-alg' => 'kms',
            'x-amz-matdesc' => Json.dump(encryption_context)
          }
          [envelope, cipher]
        end

        # @return [Cipher] Given an encryption envelope, returns a
        #   decryption cipher.
        def decryption_cipher(envelope, options = {})
          encryption_context = Json.load(envelope['x-amz-matdesc'])
          cek_alg = envelope['x-amz-cek-alg']

          case envelope['x-amz-wrap-alg']
          when 'kms'; # NO OP
          when 'kms+context'
            if cek_alg != encryption_context['aws:x-amz-cek-alg']
              raise Errors::DecryptionError, 'Value of cek-alg from envelope'\
              ' does not match the value in the encryption context'
            end
          when 'AES/GCM'
            raise ArgumentError, 'Key mismatch - Client is configured' \
                    ' with a KMS key and the x-amz-wrap-alg is AES/GCM.'
          when 'RSA-OAEP-SHA1'
            raise ArgumentError, 'Key mismatch - Client is configured' \
                    ' with a KMS key and the x-amz-wrap-alg is RSA-OAEP-SHA1.'
          else
            raise ArgumentError, 'Unsupported wrap-alg: ' \
                "#{envelope['x-amz-wrap-alg']}"
          end

          key = Aws::Plugins::UserAgent.feature('S3CryptoV1n') do
            @kms_client.decrypt(
              ciphertext_blob: decode64(envelope['x-amz-key-v2']),
              encryption_context: encryption_context
            ).plaintext
          end

          iv = decode64(envelope['x-amz-iv'])
          block_mode =
            case cek_alg
            when 'AES/CBC/PKCS5Padding'
              :CBC
            when 'AES/CBC/PKCS7Padding'
              :CBC
            when 'AES/GCM/NoPadding'
              :GCM
            else
              type = envelope['x-amz-cek-alg'].inspect
              msg = "unsupported content encrypting key (cek) format: #{type}"
              raise Errors::DecryptionError, msg
            end
          Utils.aes_decryption_cipher(block_mode, key, iv)
        end

        private

        def build_encryption_context(cek_alg, options = {})
          kms_context = (options[:kms_encryption_context] || {})
                        .each_with_object({}) { |(k, v), h| h[k.to_s] = v }
          {
            'aws:x-amz-cek-alg' => cek_alg
          }.merge(kms_context)
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
