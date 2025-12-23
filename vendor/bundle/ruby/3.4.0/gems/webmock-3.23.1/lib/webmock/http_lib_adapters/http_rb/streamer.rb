# frozen_string_literal: true

module HTTP
  class Response
    class Streamer
      def initialize(str, encoding: Encoding::BINARY)
        @io = StringIO.new str
        @encoding = encoding
      end

      def readpartial(size = nil, outbuf = nil)
        unless size
          if defined?(HTTP::Client::BUFFER_SIZE)
            size = HTTP::Client::BUFFER_SIZE
          elsif defined?(HTTP::Connection::BUFFER_SIZE)
            size = HTTP::Connection::BUFFER_SIZE
          end
        end

        chunk = @io.read size, outbuf
        chunk.force_encoding(@encoding) if chunk
      end

      def close
        @io.close
      end

      def sequence_id
        -1
      end
    end
  end
end
