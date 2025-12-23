# frozen_string_literal: true

require 'base64'

module Aws
  module S3
    module Encryption
      # @api private
      class EncryptHandler < Seahorse::Client::Handler

        def call(context)
          envelope, cipher = context[:encryption][:cipher_provider].encryption_cipher
          apply_encryption_envelope(context, envelope, cipher)
          apply_encryption_cipher(context, cipher)
          apply_cse_user_agent(context)
          @handler.call(context)
        end

        private

        def apply_encryption_envelope(context, envelope, cipher)
          context[:encryption][:cipher] = cipher
          if context[:encryption][:envelope_location] == :metadata
            context.params[:metadata] ||= {}
            context.params[:metadata].update(envelope)
          else # :instruction_file
            suffix = context[:encryption][:instruction_file_suffix]
            context.client.put_object(
              bucket: context.params[:bucket],
              key: context.params[:key] + suffix,
              body: Json.dump(envelope)
            )
          end
        end

        def apply_encryption_cipher(context, cipher)
          io = context.params[:body] || ''
          io = StringIO.new(io) if String === io
          context.params[:body] = IOEncrypter.new(cipher, io)
          context.params[:metadata] ||= {}
          context.params[:metadata]['x-amz-unencrypted-content-length'] = io.size
          if context.params.delete(:content_md5)
            warn('Setting content_md5 on client side encrypted objects is deprecated')
          end
          context.http_response.on_headers do
            context.params[:body].close
          end
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
