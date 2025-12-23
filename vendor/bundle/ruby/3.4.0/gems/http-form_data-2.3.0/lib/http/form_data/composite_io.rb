# frozen_string_literal: true

require "stringio"

module HTTP
  module FormData
    # Provides IO interface across multiple IO objects.
    class CompositeIO
      # @param [Array<IO>] ios Array of IO objects
      def initialize(ios)
        @index  = 0
        @buffer = "".b
        @ios    = ios.map do |io|
          if io.is_a?(String)
            StringIO.new(io)
          elsif io.respond_to?(:read)
            io
          else
            raise ArgumentError,
              "#{io.inspect} is neither a String nor an IO object"
          end
        end
      end

      # Reads and returns partial content acrosss multiple IO objects.
      #
      # @param [Integer] length Number of bytes to retrieve
      # @param [String] outbuf String to be replaced with retrieved data
      #
      # @return [String, nil]
      def read(length = nil, outbuf = nil)
        data   = outbuf.clear.force_encoding(Encoding::BINARY) if outbuf
        data ||= "".b

        read_chunks(length) { |chunk| data << chunk }

        data unless length && data.empty?
      end

      # Returns sum of all IO sizes.
      def size
        @size ||= @ios.map(&:size).inject(0, :+)
      end

      # Rewinds all IO objects and set cursor to the first IO object.
      def rewind
        @ios.each(&:rewind)
        @index = 0
      end

      private

      # Yields chunks with total length up to `length`.
      def read_chunks(length = nil)
        while (chunk = readpartial(length))
          yield chunk.force_encoding(Encoding::BINARY)

          next if length.nil?

          length -= chunk.bytesize

          break if length.zero?
        end
      end

      # Reads chunk from current IO with length up to `max_length`.
      def readpartial(max_length = nil)
        while current_io
          chunk = current_io.read(max_length, @buffer)

          return chunk if chunk && !chunk.empty?

          advance_io
        end
      end

      # Returns IO object under the cursor.
      def current_io
        @ios[@index]
      end

      # Advances cursor to the next IO object.
      def advance_io
        @index += 1
      end
    end
  end
end
