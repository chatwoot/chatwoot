# frozen_string_literal: true

require 'openssl'

module Aws
  module S3
    module Plugins
      # @api private
      # This plugin is effectively deprecated in favor of modeled
      # httpChecksumRequired traits.
      class Md5s < Seahorse::Client::Plugin
        # These operations allow Content MD5 but are not required by
        # httpChecksumRequired. This list should not grow.
        OPTIONAL_OPERATIONS = [
          :put_object,
          :upload_part
        ]

        # @api private
        class Handler < Seahorse::Client::Handler

          CHUNK_SIZE = 1 * 1024 * 1024 # one MB

          def call(context)
            if !context[:checksum_algorithms] # skip in favor of flexible checksum
              body = context.http_request.body
              if body.respond_to?(:size) && body.size > 0
                context.http_request.headers['Content-Md5'] ||= md5(body)
              end
            end
            @handler.call(context)
          end

          private

          # @param [File, Tempfile, IO#read, String] value
          # @return [String<MD5>]
          def md5(value)
            if (File === value || Tempfile === value) && !value.path.nil? && File.exist?(value.path)
              OpenSSL::Digest::MD5.file(value).base64digest
            elsif value.respond_to?(:read)
              md5 = OpenSSL::Digest::MD5.new
              update_in_chunks(md5, value)
              md5.base64digest
            else
              OpenSSL::Digest::MD5.digest(value).base64digest
            end
          end

          def update_in_chunks(digest, io)
            loop do
              chunk = io.read(CHUNK_SIZE)
              break unless chunk
              digest.update(chunk)
            end
            io.rewind
          end

        end

        option(:compute_checksums,
          default: true,
          doc_type: 'Boolean',
          docstring: <<-DOCS)
When `true` a MD5 checksum will be computed and sent in the Content Md5
header for :put_object and :upload_part. When `false`, MD5 checksums
will not be computed for these operations. Checksums are still computed
for operations requiring them. Checksum errors returned by Amazon S3 are
automatically retried up to `:retry_limit` times.
          DOCS

        def add_handlers(handlers, config)
          if config.compute_checksums
            # priority set low to ensure md5 is computed AFTER the request is
            # built but before it is signed
            handlers.add(
              Handler,
              priority: 10, step: :build, operations: OPTIONAL_OPERATIONS
            )
          end
        end

      end
    end
  end
end
