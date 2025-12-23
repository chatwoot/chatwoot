# frozen_string_literal: true

require_relative 'subscriber'

module Datadog
  module Tracing
    module Contrib
      module ActiveSupport
        module Notifications
          # Defines behaviors for an ActiveSupport::Notifications event.
          # Compose this into a module or class, then define
          # #event_name, #span_name, and #process. You can then
          # invoke Event.subscribe! to more easily subscribe to an event.
          module Event
            def self.included(base)
              base.include(Subscriber)
              base.extend(ClassMethods)
              base.send(:on_subscribe) { base.subscribe }
            end

            # Redefines some class behaviors for a Subscriber to make
            # it a bit simpler for an Event.
            module ClassMethods
              # Publicly exposes protected method `subscribe!`
              def subscribe! # rubocop:disable Lint/UselessMethodDefinition
                super
              end

              def subscription(span_name = nil, span_options = nil, on_start: nil, on_finish: nil, trace: nil)
                super(
                  span_name || self.span_name,
                  span_options || self.span_options,
                  on_start: on_start,
                  on_finish: on_finish,
                  trace: trace
                )
              end

              def subscribe(pattern = nil, span_name = nil, span_options = nil)
                if supported?
                  super(
                    pattern || event_name,
                    span_name || self.span_name,
                    span_options || self.span_options,
                    on_start: method(:on_start),
                    on_finish: method(:on_finish),
                    trace: method(:trace?)
                  )
                end
              end

              def supported?
                true
              end

              def span_options
                {}
              end

              def report_if_exception(span, payload)
                exception = payload_exception(payload)
                span.set_error(payload[:exception]) if exception
              end

              def payload_exception(payload)
                payload[:exception_object] ||
                  payload[:exception] # Fallback for ActiveSupport < 5.0
              end

              def on_start(_span, _event, _id, _payload); end

              def on_finish(span, _event, _id, payload)
                record_exception(span, payload)
              end

              def trace?(_event, _payload)
                true
              end

              def record_exception(span, payload)
                if payload[:exception_object]
                  span.set_error(payload[:exception_object])
                elsif payload[:exception]
                  # Fallback for ActiveSupport < 5.0
                  span.set_error(payload[:exception])
                end
              end
            end
          end
        end
      end
    end
  end
end
