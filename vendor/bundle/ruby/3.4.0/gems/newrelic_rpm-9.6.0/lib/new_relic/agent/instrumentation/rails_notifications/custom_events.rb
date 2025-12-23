# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'new_relic/agent/instrumentation/custom_events_subscriber'
require 'new_relic/agent/prepend_supportability'

DependencyDetection.defer do
  @name = :custom_event_notifications

  depends_on do
    defined?(ActiveSupport::Notifications) &&
      defined?(ActiveSupport::IsolatedExecutionState)
  end

  depends_on do
    !NewRelic::Agent.config[:active_support_custom_events_names].empty? &&
      !NewRelic::Agent::Instrumentation::CustomEventsSubscriber.subscribed?
  end

  executes do
    NewRelic::Agent.logger.info('Installing notifications based ActiveSupport custom events instrumentation')
  end

  executes do
    NewRelic::Agent.config[:active_support_custom_events_names].each do |name|
      ActiveSupport::Notifications.subscribe(name, NewRelic::Agent::Instrumentation::CustomEventsSubscriber.new)
    end
  end
end
