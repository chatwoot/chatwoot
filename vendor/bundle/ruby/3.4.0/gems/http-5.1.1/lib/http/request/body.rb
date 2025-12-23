# frozen_string_literal: true

module HTTP
  class Request
    class Body
      attr_reader :source

      def initialize(source)
        @source = source

        validate_source_type!
      end

      # Returns size which should be used for the "Content-Length" header.
      #
      # @return [Integer]
      def size
        if @source.is_a?(String)
          @source.bytesize
        elsif @source.respond_to?(:read)
          raise RequestError, "IO object must respond to #size" unless @source.respond_to?(:size)

          @source.size
        elsif @source.nil?
          0
        else
          raise RequestError, "cannot determine size of body: #{@source.inspect}"
        end
      end

      # Yields chunks of content to be streamed to the request body.
      #
      # @yieldparam [String]
      def each(&block)
        if @source.is_a?(String)
          yield @source
        elsif @source.respond_to?(:read)
          IO.copy_stream(@source, ProcIO.new(block))
          rewind(@source)
        elsif @source.is_a?(Enumerable)
          @source.each(&block)
        end

        self
      end

      # Request bodies are equivalent when they have the same source.
      def ==(other)
        self.class == other.class && self.source == other.source # rubocop:disable Style/RedundantSelf
      end

      private

      def rewind(io)
        io.rewind if io.respond_to? :rewind
      rescue Errno::ESPIPE, Errno::EPIPE
        # Pipe IOs respond to `:rewind` but fail when you call it.
        #
        # Calling `IO#rewind` on a pipe, fails with *ESPIPE* on MRI,
        # but *EPIPE* on jRuby.
        #
        # - **ESPIPE** -- "Illegal seek."
        #   Invalid seek operation (such as on a pipe).
        #
        # - **EPIPE** -- "Broken pipe."
        #   There is no process reading from the other end of a pipe. Every
        #   library function that returns this error code also generates
        #   a SIGPIPE signal; this signal terminates the program if not handled
        #   or blocked. Thus, your program will never actually see EPIPE unless
        #   it has handled or blocked SIGPIPE.
        #
        # See: https://www.gnu.org/software/libc/manual/html_node/Error-Codes.html
        nil
      end

      def validate_source_type!
        return if @source.is_a?(String)
        return if @source.respond_to?(:read)
        return if @source.is_a?(Enumerable)
        return if @source.nil?

        raise RequestError, "body of wrong type: #{@source.class}"
      end

      # This class provides a "writable IO" wrapper around a proc object, with
      # #write simply calling the proc, which we can pass in as the
      # "destination IO" in IO.copy_stream.
      class ProcIO
        def initialize(block)
          @block = block
        end

        def write(data)
          @block.call(data)
          data.bytesize
        end
      end
    end
  end
end
