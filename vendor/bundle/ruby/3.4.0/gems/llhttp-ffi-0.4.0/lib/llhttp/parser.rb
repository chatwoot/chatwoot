# frozen_string_literal: true

module LLHttp
  # [public] Wraps an llhttp context for parsing http requests and responses.
  #
  #   class Delegate < LLHttp::Delegate
  #     def on_message_begin
  #       ...
  #     end
  #
  #     ...
  #   end
  #
  #   parser = LLHttp::Parser.new(Delegate.new, type: :request)
  #   parser << "GET / HTTP/1.1\r\n\r\n"
  #   parser.finish
  #
  #   ...
  #
  # Introspection
  #
  #   * `LLHttp::Parser#content_length` returns the content length of the current request.
  #   * `LLHttp::Parser#method_name` returns the method name of the current response.
  #   * `LLHttp::Parser#status_code` returns the status code of the current response.
  #   * `LLHttp::Parser#http_major` returns the major http version of the current request/response.
  #   * `LLHttp::Parser#http_minor` returns the minor http version of the current request/response.
  #   * `LLHttp::Parser#keep_alive?` returns `true` if there might be more messages.
  #
  # Finishing
  #
  #   Call `LLHttp::Parser#finish` when processing is complete for the current request or response.
  #
  class Parser
    LLHTTP_TYPES = {both: 0, request: 1, response: 2}.freeze

    CALLBACKS = %i[
      on_message_begin
      on_headers_complete
      on_message_complete
      on_chunk_header
      on_chunk_complete
      on_url_complete
      on_status_complete
      on_header_field_complete
      on_header_value_complete
    ].freeze

    CALLBACKS_WITH_DATA = %i[
      on_url
      on_status
      on_header_field
      on_header_value
      on_body
    ].freeze

    # [public] The parser type; one of: `:both`, `:request`, or `:response`.
    #
    attr_reader :type

    def initialize(delegate, type: :both)
      @type, @delegate = type.to_sym, delegate

      @callbacks = Callbacks.new

      (CALLBACKS + CALLBACKS_WITH_DATA).each do |callback|
        if delegate.respond_to?(callback)
          @callbacks[callback] = method(callback).to_proc
        end
      end

      @pointer = LLHttp.rb_llhttp_init(LLHTTP_TYPES.fetch(@type), @callbacks)

      ObjectSpace.define_finalizer(self, self.class.free(@pointer))
    end

    # [public] Parse the given data.
    #
    def parse(data)
      errno = LLHttp.llhttp_execute(@pointer, data, data.length)
      raise build_error(errno) if errno > 0
    end
    alias_method :<<, :parse

    # [public] Get the content length of the current request.
    #
    def content_length
      LLHttp.rb_llhttp_content_length(@pointer)
    end

    # [public] Get the method of the current response.
    #
    def method_name
      LLHttp.rb_llhttp_method_name(@pointer)
    end

    # [public] Get the status code of the current response.
    #
    def status_code
      LLHttp.rb_llhttp_status_code(@pointer)
    end

    # [public] Get the major http version of the current request/response.
    #
    def http_major
      LLHttp.rb_llhttp_http_major(@pointer)
    end

    # [public] Get the minor http version of the current request/response.
    #
    def http_minor
      LLHttp.rb_llhttp_http_minor(@pointer)
    end

    # [public] Returns `true` if there might be more messages.
    #
    def keep_alive?
      LLHttp.llhttp_should_keep_alive(@pointer) == 1
    end

    # [public] Tells the parser we are finished.
    #
    def finish
      LLHttp.llhttp_finish(@pointer)
    end

    # [public] Get ready to parse the next request/response.
    #
    def reset
      LLHttp.llhttp_reset(@pointer)
    end

    CALLBACKS.each do |callback|
      class_eval(
        <<~RB, __FILE__, __LINE__ + 1
          private def #{callback}
            @delegate.#{callback}

            0
          rescue
            -1
          end
        RB
      )
    end

    CALLBACKS_WITH_DATA.each do |callback|
      class_eval(
        <<~RB, __FILE__, __LINE__ + 1
          private def #{callback}(buffer, length)
            @delegate.#{callback}(buffer.get_bytes(0, length))
          end
        RB
      )
    end

    private def build_error(errno)
      Error.new("Error Parsing data: #{LLHttp.llhttp_errno_name(errno)} #{LLHttp.llhttp_get_error_reason(@pointer)}")
    end

    def self.free(pointer)
      proc { LLHttp.rb_llhttp_free(pointer) }
    end
  end
end
