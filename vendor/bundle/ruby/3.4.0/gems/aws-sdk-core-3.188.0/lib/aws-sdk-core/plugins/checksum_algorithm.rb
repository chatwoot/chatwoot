# frozen_string_literal: true

module Aws
  module Plugins
    # @api private
    class ChecksumAlgorithm < Seahorse::Client::Plugin
      CHUNK_SIZE = 1 * 1024 * 1024 # one MB

      # determine the set of supported client side checksum algorithms
      # CRC32c requires aws-crt (optional sdk dependency) for support
      CLIENT_ALGORITHMS = begin
        supported = %w[SHA256 SHA1 CRC32]
        begin
          require 'aws-crt'
          supported << 'CRC32C'
        rescue LoadError
        end
        supported
      end.freeze

      # priority order of checksum algorithms to validate responses against
      # Remove any algorithms not supported by client (ie, depending on CRT availability)
      CHECKSUM_ALGORITHM_PRIORITIES = %w[CRC32C SHA1 CRC32 SHA256] & CLIENT_ALGORITHMS

      # byte size of checksums, used in computing the trailer length
      CHECKSUM_SIZE = {
        'CRC32' => 16,
        'CRC32C' => 16,
        'SHA1' => 36,
        'SHA256' => 52
      }

      # Interface for computing digests on request/response bodies
      # which may be files, strings or IO like objects
      # Applies only to digest functions that produce 32 bit integer checksums
      # (eg CRC32)
      class Digest32

        attr_reader :value

        # @param [Object] digest_fn
        def initialize(digest_fn)
          @digest_fn = digest_fn
          @value = 0
        end

        def update(chunk)
          @value = @digest_fn.call(chunk, @value)
        end

        def base64digest
          Base64.encode64([@value].pack('N')).chomp
        end
      end

      def add_handlers(handlers, _config)
        handlers.add(OptionHandler, step: :initialize)
        # priority set low to ensure checksum is computed AFTER the request is
        # built but before it is signed
        handlers.add(ChecksumHandler, priority: 15, step: :build)
      end

      private

      def self.request_algorithm_selection(context)
        return unless context.operation.http_checksum

        input_member = context.operation.http_checksum['requestAlgorithmMember']
        context.params[input_member.to_sym]&.upcase if input_member
      end

      def self.request_validation_mode(context)
        return unless context.operation.http_checksum

        input_member = context.operation.http_checksum['requestValidationModeMember']
        context.params[input_member.to_sym] if input_member
      end

      def self.operation_response_algorithms(context)
        return unless context.operation.http_checksum

        context.operation.http_checksum['responseAlgorithms']
      end


      # @api private
      class OptionHandler < Seahorse::Client::Handler
        def call(context)
          context[:http_checksum] ||= {}

          # validate request configuration
          if (request_input = ChecksumAlgorithm.request_algorithm_selection(context))
            unless CLIENT_ALGORITHMS.include? request_input
              if (request_input == 'CRC32C')
                raise ArgumentError, "CRC32C requires crt support - install the aws-crt gem for support."
              else
                raise ArgumentError, "#{request_input} is not a supported checksum algorithm."
              end
            end
          end

        # validate response configuration
          if (ChecksumAlgorithm.request_validation_mode(context))
            # Compute an ordered list as the union between priority supported and the
            # operation's modeled response algorithms.
            validation_list = CHECKSUM_ALGORITHM_PRIORITIES &
              ChecksumAlgorithm.operation_response_algorithms(context)
            context[:http_checksum][:validation_list] = validation_list
          end

          @handler.call(context)
        end
      end

      # @api private
      class ChecksumHandler < Seahorse::Client::Handler

        def call(context)
          if should_calculate_request_checksum?(context)
            request_algorithm_input = ChecksumAlgorithm.request_algorithm_selection(context)
            context[:checksum_algorithms] = request_algorithm_input

            request_checksum_property = {
              'algorithm' => request_algorithm_input,
              'in' => checksum_request_in(context),
              'name' => "x-amz-checksum-#{request_algorithm_input.downcase}"
            }

            calculate_request_checksum(context, request_checksum_property)
          end

          if should_verify_response_checksum?(context)
            add_verify_response_checksum_handlers(context)
          end

          @handler.call(context)
        end

        private

        def should_calculate_request_checksum?(context)
          context.operation.http_checksum &&
            ChecksumAlgorithm.request_algorithm_selection(context)
        end

        def should_verify_response_checksum?(context)
          context[:http_checksum][:validation_list] && !context[:http_checksum][:validation_list].empty?
        end

        def calculate_request_checksum(context, checksum_properties)
          case checksum_properties['in']
          when 'header'
            header_name = checksum_properties['name']
            body = context.http_request.body_contents
            if body
              context.http_request.headers[header_name] ||=
                ChecksumAlgorithm.calculate_checksum(checksum_properties['algorithm'], body)
            end
          when 'trailer'
            apply_request_trailer_checksum(context, checksum_properties)
          end
        end

        def apply_request_trailer_checksum(context, checksum_properties)
          location_name = checksum_properties['name']

          # set required headers
          headers = context.http_request.headers
          headers['Content-Encoding'] = 'aws-chunked'
          headers['X-Amz-Content-Sha256'] = 'STREAMING-UNSIGNED-PAYLOAD-TRAILER'
          headers['X-Amz-Trailer'] = location_name

          # We currently always compute the size in the modified body wrapper - allowing us
          # to set the Content-Length header (set by content_length plugin).
          # This means we cannot use Transfer-Encoding=chunked

          if !context.http_request.body.respond_to?(:size)
            raise Aws::Errors::ChecksumError, 'Could not determine length of the body'
          end
          headers['X-Amz-Decoded-Content-Length'] = context.http_request.body.size

          context.http_request.body = AwsChunkedTrailerDigestIO.new(
            context.http_request.body,
            checksum_properties['algorithm'],
            location_name
          )
        end

        # Add events to the http_response to verify the checksum as its read
        # This prevents the body from being read multiple times
        # verification is done only once a successful response has completed
        def add_verify_response_checksum_handlers(context)
          http_response = context.http_response
          checksum_context = { }
          http_response.on_headers do |_status, headers|
            header_name, algorithm = response_header_to_verify(headers, context[:http_checksum][:validation_list])
            if header_name
              expected = headers[header_name]

              unless context[:http_checksum][:skip_on_suffix] && /-[\d]+$/.match(expected)
                checksum_context[:algorithm] = algorithm
                checksum_context[:header_name] = header_name
                checksum_context[:digest] = ChecksumAlgorithm.digest_for_algorithm(algorithm)
                checksum_context[:expected] = expected
              end
            end
          end

          http_response.on_data do |chunk|
            checksum_context[:digest].update(chunk) if checksum_context[:digest]
          end

          http_response.on_success do
            if checksum_context[:digest] &&
              (computed = checksum_context[:digest].base64digest)

              if computed != checksum_context[:expected]
                raise Aws::Errors::ChecksumError,
                      "Checksum validation failed on #{checksum_context[:header_name]} "\
                      "computed: #{computed}, expected: #{checksum_context[:expected]}"
              end

              context[:http_checksum][:validated] = checksum_context[:algorithm]
            end
          end
        end

        # returns nil if no headers to verify
        def response_header_to_verify(headers, validation_list)
          validation_list.each do |algorithm|
            header_name = "x-amz-checksum-#{algorithm}"
            return [header_name, algorithm] if headers[header_name]
          end
          nil
        end

        # determine where (header vs trailer) a request checksum should be added
        def checksum_request_in(context)
          if context.operation['authtype'].eql?('v4-unsigned-body')
            'trailer'
          else
            'header'
          end
        end

      end

      def self.calculate_checksum(algorithm, body)
        digest = ChecksumAlgorithm.digest_for_algorithm(algorithm)
        if body.respond_to?(:read)
          ChecksumAlgorithm.update_in_chunks(digest, body)
        else
          digest.update(body)
        end
        digest.base64digest
      end

      def self.digest_for_algorithm(algorithm)
        case algorithm
        when 'CRC32'
          Digest32.new(Zlib.method(:crc32))
        when 'CRC32C'
          # this will only be used if input algorithm is CRC32C AND client supports it (crt available)
          Digest32.new(Aws::Crt::Checksums.method(:crc32c))
        when 'SHA1'
          Digest::SHA1.new
        when 'SHA256'
          Digest::SHA256.new
        end
      end

      # The trailer size (in bytes) is the overhead + the trailer name +
      # the length of the base64 encoded checksum
      def self.trailer_length(algorithm, location_name)
        CHECKSUM_SIZE[algorithm] + location_name.size
      end

      def self.update_in_chunks(digest, io)
        loop do
          chunk = io.read(CHUNK_SIZE)
          break unless chunk
          digest.update(chunk)
        end
        io.rewind
      end

      # Wrapper for request body that implements application-layer
      # chunking with Digest computed on chunks + added as a trailer
      class AwsChunkedTrailerDigestIO
        CHUNK_SIZE = 16384

        def initialize(io, algorithm, location_name)
          @io = io
          @location_name = location_name
          @algorithm = algorithm
          @digest = ChecksumAlgorithm.digest_for_algorithm(algorithm)
          @trailer_io = nil
        end

        # the size of the application layer aws-chunked + trailer body
        def size
          # compute the number of chunks
          # a full chunk has 4 + 4 bytes overhead, a partial chunk is len.to_s(16).size + 4
          orig_body_size = @io.size
          n_full_chunks = orig_body_size / CHUNK_SIZE
          partial_bytes = orig_body_size % CHUNK_SIZE
          chunked_body_size = n_full_chunks * (CHUNK_SIZE + 8)
          chunked_body_size += partial_bytes.to_s(16).size + partial_bytes + 4 unless  partial_bytes.zero?
          trailer_size = ChecksumAlgorithm.trailer_length(@algorithm, @location_name)
          chunked_body_size + trailer_size
        end

        def rewind
          @io.rewind
        end

        def read(length, buf = nil)
          # account for possible leftover bytes at the end, if we have trailer bytes, send them
          if @trailer_io
            return @trailer_io.read(length, buf)
          end

          chunk = @io.read(length)
          if chunk
            @digest.update(chunk)
            application_chunked = "#{chunk.bytesize.to_s(16)}\r\n#{chunk}\r\n"
            return StringIO.new(application_chunked).read(application_chunked.size, buf)
          else
            trailers = {}
            trailers[@location_name] = @digest.base64digest
            trailers = trailers.map { |k,v| "#{k}:#{v}"}.join("\r\n")
            @trailer_io = StringIO.new("0\r\n#{trailers}\r\n\r\n")
            chunk = @trailer_io.read(length, buf)
          end
          chunk
        end
      end
    end
  end
end
