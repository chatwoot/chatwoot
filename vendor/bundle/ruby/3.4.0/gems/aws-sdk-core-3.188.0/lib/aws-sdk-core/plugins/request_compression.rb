# frozen_string_literal: true

module Aws
  module Plugins
    # @api private
    class RequestCompression < Seahorse::Client::Plugin
      DEFAULT_MIN_COMPRESSION_SIZE = 10_240
      MIN_COMPRESSION_SIZE_LIMIT = 10_485_760
      SUPPORTED_ENCODINGS = %w[gzip].freeze
      CHUNK_SIZE = 1 * 1024 * 1024 # one MB

      option(
        :disable_request_compression,
        default: false,
        doc_type: 'Boolean',
        docstring: <<-DOCS) do |cfg|
When set to 'true' the request body will not be compressed
for supported operations.
      DOCS
        resolve_disable_request_compression(cfg)
      end

      option(
        :request_min_compression_size_bytes,
        default: 10_240,
        doc_type: 'Integer',
        docstring: <<-DOCS) do |cfg|
The minimum size in bytes that triggers compression for request
bodies. The value must be non-negative integer value between 0
and 10485780 bytes inclusive.
      DOCS
        resolve_request_min_compression_size_bytes(cfg)
      end

      def after_initialize(client)
        validate_disable_request_compression_input(client.config)
        validate_request_min_compression_size_bytes_input(client.config)
      end

      def validate_disable_request_compression_input(cfg)
        unless [true, false].include?(cfg.disable_request_compression)
          raise ArgumentError,
                'Must provide either `true` or `false` for the '\
                '`disable_request_compression` configuration option.'
        end
      end

      def validate_request_min_compression_size_bytes_input(cfg)
        value = Integer(cfg.request_min_compression_size_bytes)
        unless value.between?(0, MIN_COMPRESSION_SIZE_LIMIT)
          raise ArgumentError,
                'Must provide a non-negative integer value between '\
                  '`0` and `10485760` bytes inclusive for the '\
                  '`request_min_compression_size_bytes` configuration option.'
        end
      end

      def add_handlers(handlers, _config)
        # priority set to ensure compression happens BEFORE checksum
        handlers.add(CompressionHandler, priority: 16, step: :build)
      end

      class << self
        private

        def resolve_disable_request_compression(cfg)
          value = ENV['AWS_DISABLE_REQUEST_COMPRESSION'] ||
                  Aws.shared_config.disable_request_compression(profile: cfg.profile) ||
                  'false'
          Aws::Util.str_2_bool(value)
        end

        def resolve_request_min_compression_size_bytes(cfg)
          value = ENV['AWS_REQUEST_MIN_COMPRESSION_SIZE_BYTES'] ||
                  Aws.shared_config.request_min_compression_size_bytes(profile: cfg.profile) ||
                  DEFAULT_MIN_COMPRESSION_SIZE.to_s
          Integer(value)
        end
      end

      # @api private
      class CompressionHandler < Seahorse::Client::Handler
        def call(context)
          if should_compress?(context)
            selected_encoding = request_encoding_selection(context)
            if selected_encoding
              if streaming?(context.operation.input)
                process_streaming_compression(selected_encoding, context)
              elsif context.http_request.body.size >= context.config.request_min_compression_size_bytes
                process_compression(selected_encoding, context)
              end
            end
          end
          @handler.call(context)
        end

        private

        def request_encoding_selection(context)
          encoding_list = context.operation.request_compression['encodings']
          encoding_list.find { |encoding| RequestCompression::SUPPORTED_ENCODINGS.include?(encoding) }
        end

        def update_content_encoding(encoding, context)
          headers = context.http_request.headers
          if headers['Content-Encoding']
            headers['Content-Encoding'] += ',' + encoding
          else
            headers['Content-Encoding'] = encoding
          end
        end

        def should_compress?(context)
          context.operation.request_compression &&
            !context.config.disable_request_compression
        end

        def streaming?(input)
          if payload = input[:payload_member] # checking ref and shape
            payload['streaming'] || payload.shape['streaming']
          else
            false
          end
        end

        def process_compression(encoding, context)
          case encoding
          when 'gzip'
            gzip_compress(context)
          else
            raise StandardError, "We currently do not support #{encoding} encoding"
          end
          update_content_encoding(encoding, context)
        end

        def gzip_compress(context)
          compressed = StringIO.new
          compressed.binmode
          gzip_writer = Zlib::GzipWriter.new(compressed)
          if context.http_request.body.respond_to?(:read)
            update_in_chunks(gzip_writer, context.http_request.body)
          else
            gzip_writer.write(context.http_request.body)
          end
          gzip_writer.close
          new_body = StringIO.new(compressed.string)
          context.http_request.body = new_body
        end

        def update_in_chunks(compressor, io)
          loop do
            chunk = io.read(CHUNK_SIZE)
            break unless chunk

            compressor.write(chunk)
          end
        end

        def process_streaming_compression(encoding, context)
          case encoding
          when 'gzip'
            context.http_request.body = GzipIO.new(context.http_request.body)
          else
            raise StandardError, "We currently do not support #{encoding} encoding"
          end
          update_content_encoding(encoding, context)
        end

        # @api private
        class GzipIO
          def initialize(body)
            @body = body
            @buffer = ChunkBuffer.new
            @gzip_writer = Zlib::GzipWriter.new(@buffer)
          end

          def read(length, buff = nil)
            if @gzip_writer.closed?
              # an empty string to signify an end as
              # there will be nothing remaining to be read
              StringIO.new('').read(length, buff)
              return
            end

            chunk = @body.read(length)
            if !chunk || chunk.empty?
              # closing the writer will write one last chunk
              # with a trailer (to be read from the @buffer)
              @gzip_writer.close
            else
              # flush happens first to ensure that header fields
              # are being sent over since write will override
              @gzip_writer.flush
              @gzip_writer.write(chunk)
            end

            StringIO.new(@buffer.last_chunk).read(length, buff)
          end
        end

        # @api private
        class ChunkBuffer
          def initialize
            @last_chunk = nil
          end

          attr_reader :last_chunk

          def write(data)
            @last_chunk = data
          end
        end
      end

    end
  end
end
