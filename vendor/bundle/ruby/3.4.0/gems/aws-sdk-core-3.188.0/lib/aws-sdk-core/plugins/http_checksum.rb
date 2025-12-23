# frozen_string_literal: true

require 'openssl'

module Aws
  module Plugins
    # @api private
    class HttpChecksum < Seahorse::Client::Plugin
      # @api private
      class Handler < Seahorse::Client::Handler
        CHUNK_SIZE = 1 * 1024 * 1024 # one MB

        def call(context)
          if checksum_required?(context) &&
             !context[:checksum_algorithms] # skip in favor of flexible checksum
            body = context.http_request.body
            context.http_request.headers['Content-Md5'] ||= md5(body)
          end
          @handler.call(context)
        end

        private

        def checksum_required?(context)
          context.operation.http_checksum_required ||
            (context.operation.http_checksum &&
              context.operation.http_checksum['requestChecksumRequired'])
        end

        # @param [File, Tempfile, IO#read, String] value
        # @return [String<MD5>]
        def md5(value)
          if (value.is_a?(File) || value.is_a?(Tempfile)) &&
             !value.path.nil? && File.exist?(value.path)
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

      def add_handlers(handlers, _config)
        # priority set low to ensure checksum is computed AFTER the request is
        # built but before it is signed
        handlers.add(Handler, priority: 10, step: :build)
      end

    end
  end
end
