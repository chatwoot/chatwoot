# frozen_string_literal: true

module Aws
  class EventEmitter

    def initialize
      @listeners = {}
      @validate_event = true
      @status = :sleep
      @signal_queue = Queue.new
    end

    attr_accessor :stream

    attr_accessor :encoder

    attr_accessor :validate_event

    attr_accessor :signal_queue

    def on(type, callback)
      (@listeners[type] ||= []) << callback
    end

    def signal(type, event)
      return unless @listeners[type]
      @listeners[type].each do |listener|
        listener.call(event) if event.event_type == type
      end
    end

    def emit(type, params)
      unless @stream
        raise Aws::Errors::SignalEventError.new(
          "Singaling events before making async request"\
          " is not allowed."
        )
      end
      if @validate_event && type != :end_stream
        Aws::ParamValidator.validate!(
          @encoder.rules.shape.member(type), params)
      end
      _ready_for_events?
      @stream.data(
        @encoder.encode(type, params),
        end_stream: type == :end_stream
      )
    end

    private

    def _ready_for_events?
      return true if @status == :ready

      # blocked until once initial 200 response is received
      # signal will be available in @signal_queue
      # and this check will no longer be blocked
      @signal_queue.pop
      @status = :ready
      true
    end

  end
end
