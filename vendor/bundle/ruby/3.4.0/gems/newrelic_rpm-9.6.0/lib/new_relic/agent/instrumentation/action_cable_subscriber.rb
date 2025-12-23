# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'new_relic/agent/instrumentation/notifications_subscriber'

module NewRelic
  module Agent
    module Instrumentation
      class ActionCableSubscriber < NotificationsSubscriber
        PERFORM_ACTION = 'perform_action.action_cable'.freeze

        def start_segment(name, id, payload) # THREAD_LOCAL_ACCESS
          finishable = if name == PERFORM_ACTION
            Tracer.start_transaction_or_segment(
              name: transaction_name_from_payload(payload),
              category: :action_cable
            )
          else
            Tracer.start_segment(name: metric_name_from_payload(name, payload))
          end
          push_segment(id, finishable)
        end

        private

        def transaction_name_from_payload(payload)
          "Controller/ActionCable/#{payload[:channel_class]}/#{payload[:action]}"
        end

        def metric_name_from_payload(name, payload)
          "Ruby/ActionCable/#{metric_name(payload)}/#{action_name(name)}"
        end

        def metric_name(payload)
          payload[:broadcasting] || payload[:channel_class]
        end

        DOT_ACTION_CABLE = '.action_cable'.freeze

        def action_name(name)
          name.gsub(DOT_ACTION_CABLE, NewRelic::EMPTY_STR)
        end
      end
    end
  end
end
