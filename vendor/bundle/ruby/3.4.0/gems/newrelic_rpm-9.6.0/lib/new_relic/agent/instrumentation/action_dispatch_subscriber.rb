# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'new_relic/agent/instrumentation/notifications_subscriber'

module NewRelic
  module Agent
    module Instrumentation
      class ActionDispatchSubscriber < NotificationsSubscriber
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

        def metric_name(name, payload)
          middleware = payload[:middleware]
          method = method_from_name(name)
          "Ruby/ActionDispatch/#{middleware}/#{method}"
        end

        PATTERN = /\A([^\.]+)\.action_dispatch\z/
        UNKNOWN = 'unknown'.freeze

        METHOD_NAME_MAPPING = Hash.new do |h, k|
          if PATTERN =~ k
            h[k] = $1
          else
            h[k] = UNKNOWN
          end
        end

        def method_from_name(name)
          METHOD_NAME_MAPPING[name]
        end
      end
    end
  end
end
