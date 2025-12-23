# frozen_string_literal: true

require_relative 'ext'

module Datadog
  module ErrorTracking
    # The Collector is in charge, for a SpanOperation of storing the span events
    # created when an error is handled. Each SpanOperation has a Collector as soon
    # as a span event is created and the Collector has the same life time as the SpanOp.
    #
    # If an error is handled then rethrown, the SpanEvent corresponding to the error
    # will be deleted. That is why we do not add directly the SpanEvent to the SpanOp.
    #
    # @api private
    class Collector
      SPAN_EVENTS_LIMIT = 100
      LOCK = Mutex.new
      # Proc called when the span_operation :after_stop event is published
      def self.after_stop
        @after_stop ||= proc do |span_op, error|
          # if this proc is called, we are sure that span_op has a collector
          collector = span_op.get_collector_or_initialize
          # if an error exited the scope of the span, we delete the corresponding SpanEvent.
          collector.on_error(span_op, error) if error

          span_events = collector.span_events
          span_op.span_events.concat(span_events)
        end
      end

      def initialize
        @span_event_per_error = {}
      end

      def add_span_event(span_op, span_event, error)
        # When this is the first time we add a span event for a span,
        # we suscribe to the :after_stop event
        if @span_event_per_error.empty?
          events = span_op.send(:events)
          events.after_stop.subscribe(&self.class.after_stop)

          # This tag is used by the Error Tracking product to report
          # the error in Error Tracking
          span_op.set_tag(Ext::SPAN_EVENTS_HAS_EXCEPTION, true)
        end
        # Set a limit to the number of span event we can store per SpanOp
        # If an error has been handled several times in the same span we can still
        # modify the event (even if the capacity is reached) in order to report
        # the information of the last rescue
        if @span_event_per_error.key?(error) || @span_event_per_error.length < SPAN_EVENTS_LIMIT
          @span_event_per_error[error] = span_event
        end
      end

      if RUBY_VERSION >= Ext::RUBY_VERSION_WITH_RESCUE_EVENT
        # Starting from ruby3.3, as we are listening to :rescue event,
        # we just want to remove the span event if the error was
        # previously handled
        def on_error(_span_op, error)
          @span_event_per_error.delete(error)
        end
      else
        # Up to ruby3.2, we are listening to :raise event. We need to ensure
        # that an error exiting the scope of a span is not handled in a parent span.
        # This function will propagate the span event to the parent span. If the
        # error is not handled in the parent span, it will be deleted by design.
        def on_error(span_op, error)
          return unless @span_event_per_error.key?(error)

          unless span_op.root?
            parent = span_op.send(:parent)
            LOCK.synchronize do
              parent_collector = parent.get_collector_or_initialize { Collector.new }
              parent_collector.add_span_event(parent, @span_event_per_error[error], error)
            end
          end

          @span_event_per_error.delete(error)
        end
      end

      def span_events
        @span_event_per_error.values
      end
    end
  end
end
