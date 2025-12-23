# frozen_string_literal: true

require 'forwardable'

module Aws
  module S3
    module Plugins

      # A wrapper around BlockIO that adds no-ops for truncate and rewind
      # @api private
      class RetryableBlockIO
        extend Forwardable
        def_delegators :@block_io, :write, :read, :size

        def initialize(block_io)
          @block_io = block_io
        end

        def truncate(_integer); end

        def rewind; end
      end

      # A wrapper around ManagedFile that adds no-ops for truncate and rewind
      # @api private
      class RetryableManagedFile
        extend Forwardable
        def_delegators :@file, :write, :read, :size, :open?, :close

        def initialize(managed_file)
          @file = managed_file
        end

        def truncate(_integer); end

        def rewind; end
      end

      class NonRetryableStreamingError < StandardError

        def initialize(error)
          super('Unable to retry request - retry could result in processing duplicated chunks.')
          set_backtrace(error.backtrace)
          @original_error = error
        end

        attr_reader :original_error
      end

      # This handler works with the ResponseTarget plugin to provide smart
      # retries of S3 streaming operations that support the range parameter
      # (currently only: get_object).  When a 200 OK with a TruncatedBodyError
      # is received this handler will add a range header that excludes the
      # data that has already been processed (written to file or sent to
      # the target Proc).
      # It is important to not write data to the custom target in the case of
      # a non-success response. We do not want to write an XML error
      # message to someone's file or pass it to a user's Proc.
      # @api private
      class StreamingRetry < Seahorse::Client::Plugin

        class Handler < Seahorse::Client::Handler

          def call(context)
            target = context.params[:response_target] || context[:response_target]

            # retry is only supported when range is NOT set on the initial request
            if supported_target?(target) && !context.params[:range]
              add_event_listeners(context, target)
            end
            @handler.call(context)
          end

          private

          def add_event_listeners(context, target)
            context.http_response.on_headers(200..299) do
              case context.http_response.body
              when Seahorse::Client::BlockIO then
                context.http_response.body = RetryableBlockIO.new(context.http_response.body)
              when Seahorse::Client::ManagedFile then
                context.http_response.body = RetryableManagedFile.new(context.http_response.body)
              end
            end

            context.http_response.on_headers(400..599) do
              context.http_response.body = StringIO.new # something to write the error to
            end

            context.http_response.on_success(200..299) do
              body = context.http_response.body
              if body.is_a?(RetryableManagedFile) && body.open?
                body.close
              end
            end

            context.http_response.on_error do |error|
              if retryable_body?(context)
                if truncated_body?(error)
                  context.http_request.headers[:range] = "bytes=#{context.http_response.body.size}-"
                else
                  case context.http_response.body
                  when RetryableManagedFile
                    # call rewind on the underlying file
                    context.http_response.body.instance_variable_get(:@file).rewind
                  else
                    raise NonRetryableStreamingError, error
                  end
                end
              end
            end
          end

          def truncated_body?(error)
            error.is_a?(Seahorse::Client::NetworkingError) &&
              error.original_error.is_a?(
                Seahorse::Client::NetHttp::Handler::TruncatedBodyError
              )
          end

          def retryable_body?(context)
            context.http_response.body.is_a?(RetryableBlockIO) ||
              context.http_response.body.is_a?(RetryableManagedFile)
          end

          def supported_target?(target)
            case target
            when Proc, String, Pathname then true
            else false
            end
          end
        end

        handler(Handler, step: :sign, operations: [:get_object], priority: 10)

      end
    end
  end
end
