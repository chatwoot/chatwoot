# frozen_string_literal: true

require 'base64'

module Aws
  module S3
    module EncryptionV2
      # @api private
      class DefaultCipherProvider

        def initialize(options = {})
          @key_provider = options[:key_provider]
          @key_wrap_schema = validate_key_wrap(
            options[:key_wrap_schema],
            @key_provider.encryption_materials.key
          )
          @content_encryption_schema = validate_cek(
            options[:content_encryption_schema]
          )
        end

        # @return [Array<Hash,Cipher>] Creates an returns a new encryption
        #   envelope and encryption cipher.
        def encryption_cipher(options = {})
          validate_options(options)
          cipher = Utils.aes_encryption_cipher(:GCM)
          if @key_provider.encryption_materials.key.is_a? OpenSSL::PKey::RSA
            enc_key = encode64(
              encrypt_rsa(envelope_key(cipher), @content_encryption_schema)
            )
          else
            enc_key = encode64(
              encrypt_aes_gcm(envelope_key(cipher), @content_encryption_schema)
            )
          end
          envelope = {
            'x-amz-key-v2' => enc_key,
            'x-amz-cek-alg' => @content_encryption_schema,
            'x-amz-tag-len' => (AES_GCM_TAG_LEN_BYTES * 8).to_s,
            'x-amz-wrap-alg' => @key_wrap_schema,
            'x-amz-iv' => encode64(envelope_iv(cipher)),
            'x-amz-matdesc' => materials_description
          }
          cipher.auth_data = '' # auth_data must be set after key and iv
          [envelope, cipher]
        end

        # @return [Cipher] Given an encryption envelope, returns a
        #   decryption cipher.
        def decryption_cipher(envelope, options = {})
          validate_options(options)
          master_key = @key_provider.key_for(envelope['x-amz-matdesc'])
          if envelope.key? 'x-amz-key'
            unless options[:security_profile] == :v2_and_legacy
              raise Errors::LegacyDecryptionError
            end
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
                raise Errors::CEKAlgMismatchError unless cek_alg == envelope['x-amz-cek-alg']
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

        # Validate that the key_wrap_schema
        # is valid, supported and matches the provided key.
        # Returns the string version for the x-amz-key-wrap-alg
        def validate_key_wrap(key_wrap_schema, key)
          if key.is_a? OpenSSL::PKey::RSA
            unless key_wrap_schema == :rsa_oaep_sha1
              raise ArgumentError, ':key_wrap_schema must be set to :rsa_oaep_sha1 for RSA keys.'
            end
          else
            unless key_wrap_schema == :aes_gcm
              raise ArgumentError, ':key_wrap_schema must be set to :aes_gcm for AES keys.'
            end
          end

          case key_wrap_schema
          when :rsa_oaep_sha1 then 'RSA-OAEP-SHA1'
          when :aes_gcm then 'AES/GCM'
          when :kms_context
            raise ArgumentError, 'A kms_key_id is required when using :kms_context.'
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

        def envelope_key(cipher)
          cipher.key = cipher.random_key
        end

        def envelope_iv(cipher)
          cipher.iv = cipher.random_iv
        end

        def encrypt_aes_gcm(data, auth_data)
          Utils.encrypt_aes_gcm(@key_provider.encryption_materials.key, data, auth_data)
        end

        def encrypt_rsa(data, auth_data)
          Utils.encrypt_rsa(@key_provider.encryption_materials.key, data, auth_data)
        end

        def materials_description
          @key_provider.encryption_materials.description
        end

        def encode64(str)
          Base64.encode64(str).split("\n") * ''
        end

        def decode64(str)
          Base64.decode64(str)
        end

        def validate_options(options)
          if !options[:kms_encryption_context].nil?
            raise ArgumentError, 'Cannot provide :kms_encryption_context ' \
            'with non KMS client.'
          end
        end
      end
    end
  end
end
