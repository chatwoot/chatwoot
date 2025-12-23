# frozen_string_literal: true

require 'base64'

module Aws
  module S3
    module EncryptionV2
      # @api private
      class KmsCipherProvider

        def initialize(options = {})
          @kms_key_id = validate_kms_key(options[:kms_key_id])
          @kms_client = options[:kms_client]
          @key_wrap_schema = validate_key_wrap(
            options[:key_wrap_schema]
          )
          @content_encryption_schema = validate_cek(
            options[:content_encryption_schema]
          )
        end

        # @return [Array<Hash,Cipher>] Creates and returns a new encryption
        #   envelope and encryption cipher.
        def encryption_cipher(options = {})
          validate_key_for_encryption
          encryption_context = build_encryption_context(@content_encryption_schema, options)
          key_data = Aws::Plugins::UserAgent.feature('S3CryptoV2') do
            @kms_client.generate_data_key(
              key_id: @kms_key_id,
              encryption_context: encryption_context,
              key_spec: 'AES_256'
            )
          end
          cipher = Utils.aes_encryption_cipher(:GCM)
          cipher.key = key_data.plaintext
          envelope = {
            'x-amz-key-v2' => encode64(key_data.ciphertext_blob),
            'x-amz-iv' => encode64(cipher.iv = cipher.random_iv),
            'x-amz-cek-alg' => @content_encryption_schema,
            'x-amz-tag-len' => (AES_GCM_TAG_LEN_BYTES * 8).to_s,
            'x-amz-wrap-alg' => @key_wrap_schema,
            'x-amz-matdesc' => Json.dump(encryption_context)
          }
          cipher.auth_data = '' # auth_data must be set after key and iv
          [envelope, cipher]
        end

        # @return [Cipher] Given an encryption envelope, returns a
        #   decryption cipher.
        def decryption_cipher(envelope, options = {})
          encryption_context = Json.load(envelope['x-amz-matdesc'])
          cek_alg = envelope['x-amz-cek-alg']

          case envelope['x-amz-wrap-alg']
          when 'kms'
            unless options[:security_profile] == :v2_and_legacy
              raise Errors::LegacyDecryptionError
            end
          when 'kms+context'
            if cek_alg != encryption_context['aws:x-amz-cek-alg']
              raise Errors::CEKAlgMismatchError
            end

            if encryption_context != build_encryption_context(cek_alg, options)
              raise Errors::DecryptionError, 'Value of encryption context from'\
                ' envelope does not match the provided encryption context'
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

          any_cmk_mode = false || options[:kms_allow_decrypt_with_any_cmk]
          decrypt_options = {
            ciphertext_blob: decode64(envelope['x-amz-key-v2']),
            encryption_context: encryption_context
          }
          unless any_cmk_mode
            decrypt_options[:key_id] = @kms_key_id
          end

          key = Aws::Plugins::UserAgent.feature('S3CryptoV2') do
            @kms_client.decrypt(decrypt_options).plaintext
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

        def validate_key_wrap(key_wrap_schema)
          case key_wrap_schema
          when :kms_context then 'kms+context'
          else
            raise ArgumentError, "Unsupported key_wrap_schema: #{key_wrap_schema}"
          end
        end

        def validate_cek(content_encryption_schema)
          case content_encryption_schema
          when :aes_gcm_no_padding
            "AES/GCM/NoPadding"
          else
            raise ArgumentError, "Unsupported content_encryption_schema: #{content_encryption_schema}"
          end
        end

        def validate_kms_key(kms_key_id)
          if kms_key_id.nil? || kms_key_id.length.zero?
            raise ArgumentError, 'KMS CMK ID was not specified. ' \
              'Please specify a CMK ID, ' \
              'or set kms_key_id: :kms_allow_decrypt_with_any_cmk to use ' \
              'any valid CMK from the object.'
          end

          if kms_key_id.is_a?(Symbol) && kms_key_id != :kms_allow_decrypt_with_any_cmk
            raise ArgumentError, 'kms_key_id must be a valid KMS CMK or be ' \
              'set to :kms_allow_decrypt_with_any_cmk'
          end
          kms_key_id
        end

        def build_encryption_context(cek_alg, options = {})
          kms_context = (options[:kms_encryption_context] || {})
            .each_with_object({}) { |(k, v), h| h[k.to_s] = v }
          if kms_context.include? 'aws:x-amz-cek-alg'
            raise ArgumentError, 'Conflict in reserved KMS Encryption Context ' \
              'key aws:x-amz-cek-alg. This value is reserved for the S3 ' \
              'Encryption Client and cannot be set by the user.'
          end
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

        def validate_key_for_encryption
          if @kms_key_id == :kms_allow_decrypt_with_any_cmk
            raise ArgumentError, 'Unable to encrypt/write objects with '\
              'kms_key_id = :kms_allow_decrypt_with_any_cmk.  Provide ' \
              'a valid kms_key_id on client construction.'
          end
        end
      end
    end
  end
end
