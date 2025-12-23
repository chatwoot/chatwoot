# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'new_relic/agent/instrumentation/notifications_subscriber'

# Listen for ActiveSupport::Notifications events for custom events
module NewRelic::Agent::Instrumentation
  class CustomEventsSubscriber < NotificationsSubscriber
    def start(name, id, _payload) # THREAD_LOCAL_ACCESS
      return unless state.is_execution_traced?

      finishable = NewRelic::Agent::Tracer.start_transaction_or_segment(name: transaction_name(name),
        category: :custom_events)
      push_segment(id, finishable)
    rescue => e
      log_notification_error(e, name, 'start')
    end

    def finish(name, id, payload) # THREAD_LOCAL_ACCESS
      return unless state.is_execution_traced?

      NewRelic::Agent.notice_error(payload[:exception_object]) if payload.key?(:exception_object)

      finishable = pop_segment(id)
      # the following line needs else branch coverage
      finishable.finish if finishable # rubocop:disable Style/SafeNavigation
    rescue => e
      log_notification_error(e, name, 'finish')
    end

    private

    def transaction_name(name)
      "ActiveSupport/CustomEvents/#{name}"
    end
  end
end
