module Sentry
  module Rails
    module Tracing
      class AbstractSubscriber
        class << self
          def subscribe!
            raise NotImplementedError
          end

          def unsubscribe!
            self::EVENT_NAMES.each do |name|
              ActiveSupport::Notifications.unsubscribe(name)
            end
          end

          if ::Rails.version.to_i == 5
            def subscribe_to_event(event_names)
              event_names.each do |event_name|
                ActiveSupport::Notifications.subscribe(event_name) do |*args|
                  next unless Tracing.get_current_transaction

                  event = ActiveSupport::Notifications::Event.new(*args)
                  yield(event_name, event.duration, event.payload)
                end
              end
            end
          else
            def subscribe_to_event(event_names)
              event_names.each do |event_name|
                ActiveSupport::Notifications.subscribe(event_name) do |event|
                  next unless Tracing.get_current_transaction

                  yield(event_name, event.duration, event.payload)
                end
              end
            end
          end

          def record_on_current_span(duration:, **options)
            return unless options[:start_timestamp]

            Sentry.with_child_span(**options) do |child_span|
              # duration in ActiveSupport is computed in millisecond
              # so we need to covert it as second before calculating the timestamp
              child_span.set_timestamp(child_span.start_timestamp + duration / 1000)
              yield(child_span) if block_given?
            end
          end
        end
      end
    end
  end
end
