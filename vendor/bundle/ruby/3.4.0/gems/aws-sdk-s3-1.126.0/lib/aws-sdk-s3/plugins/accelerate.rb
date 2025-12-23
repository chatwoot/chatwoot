# frozen_string_literal: true

module Aws
  module S3
    module Plugins
      # Provides support for using `Aws::S3::Client` with Amazon S3 Transfer
      # Acceleration.
      #
      # Go here for more information about transfer acceleration:
      # [http://docs.aws.amazon.com/AmazonS3/latest/dev/transfer-acceleration.html](http://docs.aws.amazon.com/AmazonS3/latest/dev/transfer-acceleration.html)
      class Accelerate < Seahorse::Client::Plugin
        option(
          :use_accelerate_endpoint,
          default: false,
          doc_type: 'Boolean',
          docstring: <<-DOCS)
When set to `true`, accelerated bucket endpoints will be used
for all object operations. You must first enable accelerate for
each bucket. [Go here for more information](http://docs.aws.amazon.com/AmazonS3/latest/dev/transfer-acceleration.html).
          DOCS

        def add_handlers(handlers, config)
          operations = config.api.operation_names - [
            :create_bucket, :list_buckets, :delete_bucket
          ]
          handlers.add(
            OptionHandler, step: :initialize, operations: operations
          )
        end

        # @api private
        class OptionHandler < Seahorse::Client::Handler
          def call(context)
            # Support client configuration and per-operation configuration
            # TODO: move this to an options hash and warn here.
            if context.params.is_a?(Hash)
              accelerate = context.params.delete(:use_accelerate_endpoint)
            end
            if accelerate.nil?
              accelerate = context.config.use_accelerate_endpoint
            end
            context[:use_accelerate_endpoint] = accelerate
            @handler.call(context)
          end
        end
      end
    end
  end
end
