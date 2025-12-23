# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic
  module Agent
    module Instrumentation
      class NotificationsSubscriber
        def initialize
          @queue_key = ['NewRelic', self.class.name, object_id].join('-')
          define_exception_method
        end

        def self.subscribed?
          find_all_subscribers.find { |s| s.instance_variable_get(:@delegate).class == self }
        end

        def self.find_all_subscribers
          # TODO: need to talk to Rails core about an API for this,
          # rather than digging through Listener ivars
          instance_variable_names = [:@subscribers, :@string_subscribers, :@other_subscribers]
          all_subscribers = []

          notifier = ActiveSupport::Notifications.notifier

          instance_variable_names.each do |name|
            if notifier.instance_variable_defined?(name)
              subscribers = notifier.instance_variable_get(name)
              if subscribers.is_a?(Array)
                # Rails 5 @subscribers, and Rails 6 @other_subscribers is a
                # plain array of subscriber objects
                all_subscribers += subscribers
              elsif subscribers.is_a?(Hash)
                # Rails 6 @string_subscribers is a Hash mapping the pattern
                # string of a subscriber to an array of subscriber objects
                subscribers.values.each { |array| all_subscribers += array }
              end
            end
          end

          all_subscribers
        end

        def self.subscribe(pattern)
          if !subscribed?
            ActiveSupport::Notifications.subscribe(pattern, new)
          end
        end

        # The agent doesn't use the traditional ActiveSupport::Notifications.subscribe
        # pattern due to threading issues discovered on initial instrumentation.
        # Instead we define a #start and #finish method, which Rails responds to.
        # See: https://github.com/rails/rails/issues/12069
        def start(name, id, payload)
          return unless state.is_execution_traced?

          start_segment(name, id, payload)
        rescue => e
          log_notification_error(e, name, 'start')
        end

        def finish(name, id, payload)
          return unless state.is_execution_traced?

          finish_segment(id, payload)
        rescue => e
          log_notification_error(e, name, 'finish')
        end

        def start_segment(name, id, payload)
          segment = Tracer.start_segment(name: metric_name(name, payload))
          add_segment_params(segment, payload)
          push_segment(id, segment)
        end

        def finish_segment(id, payload)
          if segment = pop_segment(id)
            if exception = exception_object(payload)
              segment.notice_error(exception)
            end
            segment.finish
          end
        end

        # for subclasses
        def add_segment_params(segment, payload)
          # no op
        end

        # for subclasses
        def metric_name(name, payload)
          "Ruby/#{name}"
        end

        def log_notification_error(error, name, event_type)
          # These are important enough failures that we want the backtraces
          # logged at error level, hence the explicit log_exception call.
          NewRelic::Agent.logger.error("Error during #{event_type} callback for event '#{name}':")
          NewRelic::Agent.logger.log_exception(:error, error)
        end

        def push_segment(id, segment)
          segment_stack[id].push(segment)
        end

        def pop_segment(id)
          segment = segment_stack[id].pop
          segment
        end

        def segment_stack
          Thread.current[@queue_key] ||= Hash.new { |h, id| h[id] = [] }
        end

        def state
          NewRelic::Agent::Tracer.state
        end

        def define_exception_method
          # we don't expect this to be called more than once, but we're being
          # defensive.
          return if defined?(exception_object)
          return unless defined?(::ActiveSupport::VERSION)

          if ::ActiveSupport::VERSION::STRING < '5.0.0'
            # Earlier versions of Rails did not add the exception itself to the
            # payload accessible via :exception_object, so we create a stand-in
            # error object from the given class name and message.
            # NOTE: no backtrace available this way, but we can notice the error
            # well enough to send the necessary info the UI requires to present it.
            def exception_object(payload)
              exception_class, message = payload[:exception]
              return nil unless exception_class

              NewRelic::Agent::NoticeableError.new(exception_class, message)
            end
          else
            def exception_object(payload)
              payload[:exception_object]
            end
          end
        end
      end
    end
  end
end
