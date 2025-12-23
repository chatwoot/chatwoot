# frozen_string_literal: true

require 'pathname'

module Seahorse
  module Client
    module Plugins
      # @api private
      class ResponseTarget < Plugin

        # This handler is responsible for replacing the HTTP response body IO
        # object with custom targets, such as a block, or a file. It is important
        # to not write data to the custom target in the case of a non-success
        # response. We do not want to write an XML error message to someone's
        # file.
        class Handler < Client::Handler

          def call(context)
            if context.params.is_a?(Hash) && context.params[:response_target]
              context[:response_target] = context.params.delete(:response_target)
            end
            target = context[:response_target]
            add_event_listeners(context, target) if target
            @handler.call(context)
          end

          private

          def add_event_listeners(context, target)
            context.http_response.on_headers(200..299) do
              # In a fresh response body will be a StringIO
              # However, when a request is retried we may have
              # an existing ManagedFile or BlockIO and those
              # should be reused.
              if context.http_response.body.is_a? StringIO
                context.http_response.body = io(target, context.http_response.headers)
              end
            end

            context.http_response.on_success(200..299) do
              body = context.http_response.body
              if body.is_a?(ManagedFile) && body.open?
                body.close
              end
            end

            context.http_response.on_error do
              body = context.http_response.body

              # When using response_target of file we do not want to write
              # error messages to the file.  So set the body to a new StringIO
              if body.is_a? ManagedFile
                File.unlink(body)
                context.http_response.body = StringIO.new
              end

              # Aws::S3::Encryption::DecryptHandler (with lower priority)
              # has callbacks registered after ResponseTarget::Handler,
              # where http_response.body is an IODecrypter
              # and has error callbacks handling for it so no action is required here
            end
          end

          def io(target, headers)
            case target
            when Proc then BlockIO.new(headers, &target)
            when String, Pathname then ManagedFile.new(target, 'w+b')
            else target
            end
          end

        end

        handler(Handler, step: :initialize, priority: 90)

      end
    end
  end
end
