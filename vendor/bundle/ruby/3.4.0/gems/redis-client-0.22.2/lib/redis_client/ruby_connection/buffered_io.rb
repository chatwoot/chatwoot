# frozen_string_literal: true

require "io/wait" unless IO.method_defined?(:wait_readable) && IO.method_defined?(:wait_writable)

class RedisClient
  class RubyConnection
    class BufferedIO
      EOL = "\r\n".b.freeze
      EOL_SIZE = EOL.bytesize

      attr_accessor :read_timeout, :write_timeout

      if String.method_defined?(:byteindex) # Ruby 3.2+
        ENCODING = Encoding::UTF_8

        def initialize(io, read_timeout:, write_timeout:, chunk_size: 4096)
          @io = io
          @buffer = +""
          @offset = 0
          @chunk_size = chunk_size
          @read_timeout = read_timeout
          @write_timeout = write_timeout
          @blocking_reads = false
        end

        def gets_chomp
          fill_buffer(false) if @offset >= @buffer.bytesize
          until eol_index = @buffer.byteindex(EOL, @offset)
            fill_buffer(false)
          end

          line = @buffer.byteslice(@offset, eol_index - @offset)
          @offset = eol_index + EOL_SIZE
          line
        end

        def read_chomp(bytes)
          ensure_remaining(bytes + EOL_SIZE)
          str = @buffer.byteslice(@offset, bytes)
          @offset += bytes + EOL_SIZE
          str
        end

        private def ensure_line
          fill_buffer(false) if @offset >= @buffer.bytesize
          until @buffer.byteindex(EOL, @offset)
            fill_buffer(false)
          end
        end
      else
        ENCODING = Encoding::BINARY

        def initialize(io, read_timeout:, write_timeout:, chunk_size: 4096)
          @io = io
          @buffer = "".b
          @offset = 0
          @chunk_size = chunk_size
          @read_timeout = read_timeout
          @write_timeout = write_timeout
          @blocking_reads = false
        end

        def gets_chomp
          fill_buffer(false) if @offset >= @buffer.bytesize
          until eol_index = @buffer.index(EOL, @offset)
            fill_buffer(false)
          end

          line = @buffer.byteslice(@offset, eol_index - @offset)
          @offset = eol_index + EOL_SIZE
          line
        end

        def read_chomp(bytes)
          ensure_remaining(bytes + EOL_SIZE)
          str = @buffer.byteslice(@offset, bytes)
          @offset += bytes + EOL_SIZE
          str.force_encoding(Encoding::UTF_8)
        end

        private def ensure_line
          fill_buffer(false) if @offset >= @buffer.bytesize
          until @buffer.index(EOL, @offset)
            fill_buffer(false)
          end
        end
      end

      def close
        @io.to_io.close
      end

      def closed?
        @io.to_io.closed?
      end

      def eof?
        @offset >= @buffer.bytesize && @io.eof?
      end

      def with_timeout(new_timeout)
        new_timeout = false if new_timeout == 0

        previous_read_timeout = @read_timeout
        previous_blocking_reads = @blocking_reads

        if new_timeout
          @read_timeout = new_timeout
        else
          @blocking_reads = true
        end

        begin
          yield
        ensure
          @read_timeout = previous_read_timeout
          @blocking_reads = previous_blocking_reads
        end
      end

      def skip(offset)
        ensure_remaining(offset)
        @offset += offset
        nil
      end

      def write(string)
        total = remaining = string.bytesize
        loop do
          case bytes_written = @io.write_nonblock(string, exception: false)
          when Integer
            remaining -= bytes_written
            if remaining > 0
              string = string.byteslice(bytes_written..-1)
            else
              return total
            end
          when :wait_readable
            @io.to_io.wait_readable(@read_timeout) or raise(ReadTimeoutError, "Waited #{@read_timeout} seconds")
          when :wait_writable
            @io.to_io.wait_writable(@write_timeout) or raise(WriteTimeoutError, "Waited #{@write_timeout} seconds")
          when nil
            raise Errno::ECONNRESET
          else
            raise "Unexpected `write_nonblock` return: #{bytes.inspect}"
          end
        end
      end

      def getbyte
        unless byte = @buffer.getbyte(@offset)
          ensure_remaining(1)
          byte = @buffer.getbyte(@offset)
        end
        @offset += 1
        byte
      end

      def gets_integer
        int = 0
        offset = @offset
        while true
          chr = @buffer.getbyte(offset)

          if chr
            if chr == 13 # "\r".ord
              @offset = offset + 2
              break
            else
              int = (int * 10) + chr - 48
            end
            offset += 1
          else
            ensure_line
            return gets_integer
          end
        end

        int
      end

      private

      def ensure_remaining(bytes)
        needed = bytes - (@buffer.bytesize - @offset)
        if needed > 0
          fill_buffer(true, needed)
        end
      end

      def fill_buffer(strict, size = @chunk_size)
        remaining = size
        buffer_size = @buffer.bytesize
        start = @offset - buffer_size
        empty_buffer = start >= 0

        loop do
          bytes = if empty_buffer
            @io.read_nonblock([remaining, @chunk_size].max, @buffer, exception: false)
          else
            @io.read_nonblock([remaining, @chunk_size].max, exception: false)
          end

          case bytes
          when :wait_readable
            # Ref: https://github.com/redis-rb/redis-client/issues/190
            # SSLSocket always clear the provided buffer, even when it didn't
            # read anything. So we need to reset the offset accordingly.
            if empty_buffer && @buffer.empty?
              @offset -= buffer_size
            end

            unless @io.to_io.wait_readable(@read_timeout)
              raise ReadTimeoutError, "Waited #{@read_timeout} seconds" unless @blocking_reads
            end
          when :wait_writable
            # Ref: https://github.com/redis-rb/redis-client/issues/190
            # SSLSocket always clear the provided buffer, even when it didn't
            # read anything. So we need to reset the offset accordingly.
            if empty_buffer && @buffer.empty?
              @offset -= buffer_size
            end

            @io.to_io.wait_writable(@write_timeout) or raise(WriteTimeoutError, "Waited #{@write_timeout} seconds")
          when nil
            raise EOFError
          else
            if empty_buffer
              @offset = start
              empty_buffer = false
              @buffer.force_encoding(ENCODING) unless @buffer.encoding == ENCODING
            else
              @buffer << bytes.force_encoding(ENCODING)
            end
            remaining -= bytes.bytesize
            return if !strict || remaining <= 0
          end
        end
      end
    end
  end
end
