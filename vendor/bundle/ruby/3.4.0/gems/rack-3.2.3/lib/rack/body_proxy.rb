# frozen_string_literal: true

module Rack
  # Proxy for response bodies allowing calling a block when
  # the response body is closed (after the response has been fully
  # sent to the client).
  class BodyProxy
    # Set the response body to wrap, and the block to call when the
    # response has been fully sent.
    def initialize(body, &block)
      @body = body
      @block = block
      @closed = false
    end

    # Return whether the wrapped body responds to the method.
    def respond_to_missing?(method_name, include_all = false)
      case method_name
      when :to_str
        false
      else
        super or @body.respond_to?(method_name, include_all)
      end
    end

    # If not already closed, close the wrapped body and
    # then call the block the proxy was initialized with.
    def close
      return if @closed
      @closed = true
      begin
        @body.close if @body.respond_to?(:close)
      ensure
        @block.call
      end
    end

    # Whether the proxy is closed.  The proxy starts as not closed,
    # and becomes closed on the first call to close.
    def closed?
      @closed
    end

    # Delegate missing methods to the wrapped body.
    def method_missing(method_name, *args, &block)
      case method_name
      when :to_str
        super
      when :to_ary
        begin
          @body.__send__(method_name, *args, &block)
        ensure
          close
        end
      else
        @body.__send__(method_name, *args, &block)
      end
    end
    # :nocov:
    ruby2_keywords(:method_missing) if respond_to?(:ruby2_keywords, true)
    # :nocov:
  end
end
