# frozen_string_literal: true

require 'base64'

module Aws
  module S3
    module Encryption
      # @api private
      class DecryptHandler < Seahorse::Client::Handler
        @@warned_response_target_proc = false

        V1_ENVELOPE_KEYS = %w(
          x-amz-key
          x-amz-iv
          x-amz-matdesc
        )

        V2_ENVELOPE_KEYS = %w(
          x-amz-key-v2
          x-amz-iv
          x-amz-cek-alg
          x-amz-wrap-alg
          x-amz-matdesc
        )

        V2_OPTIONAL_KEYS = %w(x-amz-tag-len)

        POSSIBLE_ENVELOPE_KEYS = (V1_ENVELOPE_KEYS +
          V2_ENVELOPE_KEYS + V2_OPTIONAL_KEYS).uniq

        POSSIBLE_WRAPPING_FORMATS = %w(
          AES/GCM
          kms
          kms+context
          RSA-OAEP-SHA1
        )

        POSSIBLE_ENCRYPTION_FORMATS = %w(
          AES/GCM/NoPadding
          AES/CBC/PKCS5Padding
          AES/CBC/PKCS7Padding
        )

        AUTH_REQUIRED_CEK_ALGS = %w(AES/GCM/NoPadding)

        def call(context)
          attach_http_event_listeners(context)
          apply_cse_user_agent(context)

          if context[:response_target].is_a?(Proc) && !@@warned_response_target_proc
            @@warned_response_target_proc = true
            warn(':response_target is a Proc, or a block was provided. ' \
              'Read the entire object to the ' \
              'end before you start using the decrypted data. This is to ' \
              'verify that the object has not been modified since it ' \
              'was encrypted.')
          end

          @handler.call(context)
        end

        private

        def attach_http_event_listeners(context)

          context.http_response.on_headers(200) do
            cipher, envelope = decryption_cipher(context)
            decrypter = body_contains_auth_tag?(envelope) ?
              authenticated_decrypter(context, cipher, envelope) :
              IODecrypter.new(cipher, context.http_response.body)
            context.http_response.body = decrypter
          end

          context.http_response.on_success(200) do
            decrypter = context.http_response.body
            decrypter.finalize
            decrypter.io.rewind if decrypter.io.respond_to?(:rewind)
            context.http_response.body = decrypter.io
          end

          context.http_response.on_error do
            if context.http_response.body.respond_to?(:io)
              context.http_response.body = context.http_response.body.io
            end
          end
        end

        def decryption_cipher(context)
          if (envelope = get_encryption_envelope(context))
            cipher = context[:encryption][:cipher_provider]
                     .decryption_cipher(
                       envelope,
                       context[:encryption]
                     )
            [cipher, envelope]
          else
            raise Errors::DecryptionError, "unable to locate encryption envelope"
          end
        end

        def get_encryption_envelope(context)
          if context[:encryption][:envelope_location] == :metadata
            envelope_from_metadata(context) || envelope_from_instr_file(context)
          else
            envelope_from_instr_file(context) || envelope_from_metadata(context)
          end
        end

        def envelope_from_metadata(context)
          possible_envelope = {}
          POSSIBLE_ENVELOPE_KEYS.each do |suffix|
            if value = context.http_response.headers["x-amz-meta-#{suffix}"]
              possible_envelope[suffix] = value
            end
          end
          extract_envelope(possible_envelope)
        end

        def envelope_from_instr_file(context)
          suffix = context[:encryption][:instruction_file_suffix]
          possible_envelope = Json.load(context.client.get_object(
            bucket: context.params[:bucket],
            key: context.params[:key] + suffix
          ).body.read)
          extract_envelope(possible_envelope)
        rescue S3::Errors::ServiceError, Json::ParseError
          nil
        end

        def extract_envelope(hash)
          return nil unless hash
          return v1_envelope(hash) if hash.key?('x-amz-key')
          return v2_envelope(hash) if hash.key?('x-amz-key-v2')
          if hash.keys.any? { |key| key.match(/^x-amz-key-(.+)$/) }
            msg = "unsupported envelope encryption version #{$1}"
            raise Errors::DecryptionError, msg
          end
        end

        def v1_envelope(envelope)
          envelope
        end

        def v2_envelope(envelope)
          unless POSSIBLE_ENCRYPTION_FORMATS.include? envelope['x-amz-cek-alg']
            alg = envelope['x-amz-cek-alg'].inspect
            msg = "unsupported content encrypting key (cek) format: #{alg}"
            raise Errors::DecryptionError, msg
          end
          unless POSSIBLE_WRAPPING_FORMATS.include? envelope['x-amz-wrap-alg']
            alg = envelope['x-amz-wrap-alg'].inspect
            msg = "unsupported key wrapping algorithm: #{alg}"
            raise Errors::DecryptionError, msg
          end
          unless (missing_keys = V2_ENVELOPE_KEYS - envelope.keys).empty?
            msg = "incomplete v2 encryption envelope:\n"
            msg += "  missing: #{missing_keys.join(',')}\n"
            raise Errors::DecryptionError, msg
          end
          envelope
        end

        # This method fetches the tag from the end of the object by
        # making a GET Object w/range request. This auth tag is used
        # to initialize the cipher, and the decrypter truncates the
        # auth tag from the body when writing the final bytes.
        def authenticated_decrypter(context, cipher, envelope)
          http_resp = context.http_response
          content_length = http_resp.headers['content-length'].to_i
          auth_tag_length = auth_tag_length(envelope)

          auth_tag = context.client.get_object(
            bucket: context.params[:bucket],
            key: context.params[:key],
            range: "bytes=-#{auth_tag_length}"
          ).body.read

          cipher.auth_tag = auth_tag
          cipher.auth_data = ''

          # The encrypted object contains both the cipher text
          # plus a trailing auth tag.
          IOAuthDecrypter.new(
            io: http_resp.body,
            encrypted_content_length: content_length - auth_tag_length,
            cipher: cipher)
        end

        def body_contains_auth_tag?(envelope)
          AUTH_REQUIRED_CEK_ALGS.include?(envelope['x-amz-cek-alg'])
        end

        # Determine the auth tag length from the algorithm
        # Validate it against the value provided in the x-amz-tag-len
        # Return the tag length in bytes
        def auth_tag_length(envelope)
          tag_length =
            case envelope['x-amz-cek-alg']
            when 'AES/GCM/NoPadding' then AES_GCM_TAG_LEN_BYTES
            else
              raise ArgumentError, 'Unsupported cek-alg: ' \
                "#{envelope['x-amz-cek-alg']}"
            end
          if (tag_length * 8) != envelope['x-amz-tag-len'].to_i
            raise Errors::DecryptionError, 'x-amz-tag-len does not match expected'
          end
          tag_length
        end

        def apply_cse_user_agent(context)
          if context.config.user_agent_suffix.nil?
            context.config.user_agent_suffix = EC_USER_AGENT
          elsif !context.config.user_agent_suffix.include? EC_USER_AGENT
            context.config.user_agent_suffix += " #{EC_USER_AGENT}"
          end
        end

      end
    end
  end
end
