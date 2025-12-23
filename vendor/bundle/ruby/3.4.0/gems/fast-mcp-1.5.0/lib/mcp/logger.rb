# frozen_string_literal: true

# This class is not used yet.
module FastMcp
  class Logger < Logger
    def initialize(transport: :stdio)
      @client_initialized = false
      @transport = transport

      # we don't want to log to stdout if we're using the stdio transport
      super($stdout) unless stdio_transport?
    end

    attr_accessor :transport, :client_initialized
    alias client_initialized? client_initialized

    def stdio_transport?
      transport == :stdio
    end

    def add(severity, message = nil, progname = nil, &block)
      return if stdio_transport? # we don't want to log to stdout if we're using the stdio transport

      # TODO: implement logging as the specification requires
      super
    end

    def rack_transport?
      transport == :rack
    end
  end
end
