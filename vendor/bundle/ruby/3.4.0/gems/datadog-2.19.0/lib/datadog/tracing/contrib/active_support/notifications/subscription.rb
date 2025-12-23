# frozen_string_literal: true

module Datadog
  module Tracing
    module Contrib
      module ActiveSupport
        module Notifications
          # An ActiveSupport::Notification subscription that wraps events with tracing.
          class Subscription
            attr_accessor \
              :span_name,
              :span_options

            # @param span_name [String] the operation name for the span
            # @param span_options [Hash] span_options to pass during span creation
            # @param on_start [Proc] a block to run when the event is fired,
            #   might not include all required information in the `payload` argument.
            # @param on_finish [Proc] a block to run when the event has finished processing,
            #   possibly including more information in the `payload` argument.
            # @param trace [Proc] whether to trace the event. Defaults to returning `true`.
            def initialize(span_name, span_options, on_start: nil, on_finish: nil, trace: nil)
              raise ArgumentError, 'Must be given either on_start or on_finish' unless on_start || on_finish

              @span_name = span_name
              @span_options = span_options
              @on_start = Handler.new(on_start)
              @on_finish = Handler.new(on_finish)
              @trace = trace
              @callbacks = Callbacks.new
            end

            # Called by ActiveSupport on event start
            def start(name, id, payload)
              start_span(name, id, payload) if @trace&.call(name, payload)
            end

            # Called by ActiveSupport on event finish
            def finish(name, id, payload)
              finish_span(name, id, payload) if payload[:datadog_span]
            end

            def before_trace(&block)
              callbacks.add(:before_trace, &block) if block
            end

            def after_trace(&block)
              callbacks.add(:after_trace, &block) if block
            end

            def subscribe(pattern)
              return false if subscribers.key?(pattern)

              subscribers[pattern] = ::ActiveSupport::Notifications.subscribe(pattern, self)
              true
            end

            def unsubscribe(pattern)
              return false unless subscribers.key?(pattern)

              ::ActiveSupport::Notifications.unsubscribe(subscribers[pattern])
              subscribers.delete(pattern)
              true
            end

            def unsubscribe_all
              return false if subscribers.empty?

              subscribers.each_key { |pattern| unsubscribe(pattern) }
              true
            end

            protected

            attr_reader \
              :on_start,
              :on_finish,
              :callbacks

            def start_span(name, id, payload, start = nil)
              # Run callbacks
              callbacks.run(name, :before_trace, id, payload, start)

              # Start a trace
              span = Tracing.trace(@span_name, **@span_options)

              # Start span if time is provided
              span.start(start) unless start.nil?
              payload[:datadog_span] = span

              on_start.run(span, name, id, payload)

              span
            end

            def finish_span(name, id, payload, finish = nil)
              payload[:datadog_span].tap do |span|
                # If no active span, return.
                return nil if span.nil?

                # Run handler for event
                on_finish.run(span, name, id, payload)

                # Finish the span
                span.finish(finish)

                # Run callbacks
                callbacks.run(name, :after_trace, span, id, payload, finish)
              end
            end

            # Pattern => ActiveSupport:Notifications::Subscribers
            def subscribers
              @subscribers ||= {}
            end

            # Wrapper for subscription handler
            class Handler
              attr_reader :block

              def initialize(block)
                @block = block
              end

              def run(span, name, id, payload)
                @block.call(span, name, id, payload) if @block
              rescue StandardError => e
                Datadog.logger.debug(
                  "ActiveSupport::Notifications handler for '#{name}' failed: #{e.class.name} #{e.message}"
                )
              end
            end

            # Wrapper for subscription callbacks
            class Callbacks
              attr_reader :blocks

              def initialize
                @blocks = {}
              end

              def add(key, &block)
                blocks_for(key) << block if block
              end

              def run(event, key, *args)
                blocks_for(key).each do |callback|
                  begin
                    callback.call(event, key, *args)
                  rescue StandardError => e
                    Datadog.logger.debug(
                      "ActiveSupport::Notifications '#{key}' callback for '#{event}' failed: #{e.class.name} #{e.message}"
                    )
                  end
                end
              end

              private

              def blocks_for(key)
                blocks[key] ||= []
              end
            end
          end
        end
      end
    end
  end
end
