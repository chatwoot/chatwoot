# frozen_string_literal: true

module Aws
  module AsyncClientStubs 

    include Aws::ClientStubs

    # @api private
    def setup_stubbing
      @stubs = {}
      @stub_mutex = Mutex.new
      if Hash === @config.stub_responses
        @config.stub_responses.each do |operation_name, stubs|
          apply_stubs(operation_name, Array === stubs ? stubs : [stubs])
        end
      end

      # When a client is stubbed allow the user to access the requests made
      @api_requests = []

      # allow to access signaled events when client is stubbed
      @send_events = []

      requests = @api_requests
      send_events = @send_events

      self.handle do |context|
        if input_stream = context[:input_event_stream_handler]
          stub_stream = StubStream.new
          stub_stream.send_events = send_events
          input_stream.event_emitter.stream = stub_stream 
          input_stream.event_emitter.validate_event = context.config.validate_params
        end
        requests << {
          operation_name: context.operation_name,
          params: context.params,
          context: context
        }
        @handler.call(context)
      end
    end

    def send_events
      if config.stub_responses
        @send_events
      else
        msg = 'This method is only implemented for stubbed clients, and is '\
              'available when you enable stubbing in the constructor with `stub_responses: true`'
        raise NotImplementedError.new(msg)
      end
    end

    class StubStream

      def initialize
        @state = :open
      end

      attr_accessor :send_events

      attr_reader :state

      def data(bytes, options = {})
        if options[:end_stream]
          @state = :closed
        else
          decoder = Aws::EventStream::Decoder.new
          event = decoder.decode_chunk(bytes).first
          @send_events << decoder.decode_chunk(event.payload.read).first
        end
      end

      def closed?
        @state == :closed
      end

      def close
        @state = :closed
      end
    end
  end
end
