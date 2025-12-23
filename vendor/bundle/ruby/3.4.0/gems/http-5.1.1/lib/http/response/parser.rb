# frozen_string_literal: true

require "llhttp"

module HTTP
  class Response
    # @api private
    class Parser
      attr_reader :parser, :headers, :status_code, :http_version

      def initialize
        @handler = Handler.new(self)
        @parser = LLHttp::Parser.new(@handler, :type => :response)
        reset
      end

      def reset
        @parser.reset
        @handler.reset
        @header_finished = false
        @message_finished = false
        @headers = Headers.new
        @chunk = nil
        @status_code = nil
        @http_version = nil
      end

      def add(data)
        parser << data

        self
      rescue LLHttp::Error => e
        raise IOError, e.message
      end

      alias << add

      def mark_header_finished
        @header_finished = true
        @status_code = @parser.status_code
        @http_version = "#{@parser.http_major}.#{@parser.http_minor}"
      end

      def headers?
        @header_finished
      end

      def add_header(name, value)
        @headers.add(name, value)
      end

      def mark_message_finished
        @message_finished = true
      end

      def finished?
        @message_finished
      end

      def add_body(chunk)
        if @chunk
          @chunk << chunk
        else
          @chunk = chunk
        end
      end

      def read(size)
        return if @chunk.nil?

        if @chunk.bytesize <= size
          chunk  = @chunk
          @chunk = nil
        else
          chunk = @chunk.byteslice(0, size)
          @chunk[0, size] = ""
        end

        chunk
      end

      class Handler < LLHttp::Delegate
        def initialize(target)
          @target = target
          super()
          reset
        end

        def reset
          @reading_header_value = false
          @field_value = +""
          @field = +""
        end

        def on_header_field(field)
          append_header if @reading_header_value
          @field << field
        end

        def on_header_value(value)
          @reading_header_value = true
          @field_value << value
        end

        def on_headers_complete
          append_header if @reading_header_value
          @target.mark_header_finished
        end

        def on_body(body)
          @target.add_body(body)
        end

        def on_message_complete
          @target.mark_message_finished
        end

        private

        def append_header
          @target.add_header(@field, @field_value)
          @reading_header_value = false
          @field_value = +""
          @field = +""
        end
      end
    end
  end
end
