# frozen_string_literal: true

module Aws
  module S3
    module Plugins

      # S3 GetObject results for whole Multipart Objects contain a checksum
      # that cannot be validated.  These should be skipped by the
      # ChecksumAlgorithm plugin.
      class SkipWholeMultipartGetChecksums < Seahorse::Client::Plugin

        class Handler < Seahorse::Client::Handler

          def call(context)
            context[:http_checksum] ||= {}
            context[:http_checksum][:skip_on_suffix] = true

            @handler.call(context)
          end

        end

        handler(
          Handler,
          step: :initialize,
          operations: [:get_object]
        )
      end
    end
  end
end
