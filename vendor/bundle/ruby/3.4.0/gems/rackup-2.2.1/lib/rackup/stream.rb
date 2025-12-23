# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2023-2024, by Samuel Williams.

module Rackup
  # The input stream is an IO-like object which contains the raw HTTP POST data. When applicable, its external encoding must be “ASCII-8BIT” and it must be opened in binary mode, for Ruby 1.9 compatibility. The input stream must respond to gets, each, read and rewind.
  class Stream
    def initialize(input = nil, output = Buffered.new)
      @input = input
      @output = output

      raise ArgumentError, "Non-writable output!" unless output.respond_to?(:write)

      # Will hold remaining data in `#read`.
      @buffer = nil
      @closed = false
    end

    attr :input
    attr :output

    # This provides a read-only interface for data, which is surprisingly tricky to implement correctly.
    module Reader
      # rack.hijack_io must respond to:
      # read, write, read_nonblock, write_nonblock, flush, close, close_read, close_write, closed?

      # read behaves like IO#read. Its signature is read([length, [buffer]]). If given, length must be a non-negative Integer (>= 0) or nil, and buffer must be a String and may not be nil. If length is given and not nil, then this method reads at most length bytes from the input stream. If length is not given or nil, then this method reads all data until EOF. When EOF is reached, this method returns nil if length is given and not nil, or “” if length is not given or is nil. If buffer is given, then the read data will be placed into buffer instead of a newly created String object.
      # @param length [Integer] the amount of data to read
      # @param buffer [String] the buffer which will receive the data
      # @return a buffer containing the data
      def read(length = nil, buffer = nil)
        return '' if length == 0

        buffer ||= String.new.force_encoding(Encoding::BINARY)

        # Take any previously buffered data and replace it into the given buffer.
        if @buffer
          buffer.replace(@buffer)
          @buffer = nil
        else
          buffer.clear
        end

        if length
          while buffer.bytesize < length and chunk = read_next
            buffer << chunk
          end

          # This ensures the subsequent `slice!` works correctly.
          buffer.force_encoding(Encoding::BINARY)

          # This will be at least one copy:
          @buffer = buffer.byteslice(length, buffer.bytesize)

          # This should be zero-copy:
          buffer.slice!(length, buffer.bytesize)

          if buffer.empty?
            return nil
          else
            return buffer
          end
        else
          while chunk = read_next
            buffer << chunk
          end

          return buffer
        end
      end

      # Read at most `length` bytes from the stream. Will avoid reading from the underlying stream if possible.
      def read_partial(length = nil)
        if @buffer
          buffer = @buffer
          @buffer = nil
        else
          buffer = read_next
        end

        if buffer and length
          if buffer.bytesize > length
            # This ensures the subsequent `slice!` works correctly.
            buffer.force_encoding(Encoding::BINARY)

            @buffer = buffer.byteslice(length, buffer.bytesize)
            buffer.slice!(length, buffer.bytesize)
          end
        end

        return buffer
      end

      def gets
        read_partial
      end

      def each
        while chunk = read_partial
          yield chunk
        end
      end

      def read_nonblock(length, buffer = nil)
        @buffer ||= read_next
        chunk = nil

        unless @buffer
          buffer&.clear
          return
        end

        if @buffer.bytesize > length
          chunk = @buffer.byteslice(0, length)
          @buffer = @buffer.byteslice(length, @buffer.bytesize)
        else
          chunk = @buffer
          @buffer = nil
        end

        if buffer
          buffer.replace(chunk)
        else
          buffer = chunk
        end

        return buffer
      end
    end

    include Reader

    def write(buffer)
      if @output
        @output.write(buffer)
        return buffer.bytesize
      else
        raise IOError, "Stream is not writable, output has been closed!"
      end
    end

    def write_nonblock(buffer)
      write(buffer)
    end

    def <<(buffer)
      write(buffer)
    end

    def flush
    end

    def close_read
      @input&.close
      @input = nil
    end

    # close must never be called on the input stream. huh?
    def close_write
      if @output.respond_to?(:close)
        @output&.close
      end

      @output = nil
    end

    # Close the input and output bodies.
    def close(error = nil)
      self.close_read
      self.close_write

      return nil
    ensure
      @closed = true
    end

    # Whether the stream has been closed.
    def closed?
      @closed
    end

    # Whether there are any output chunks remaining?
    def empty?
      @output.empty?
    end

    private

    def read_next
      if @input
        return @input.read
      else
        @input = nil
        raise IOError, "Stream is not readable, input has been closed!"
      end
    end
  end
end
