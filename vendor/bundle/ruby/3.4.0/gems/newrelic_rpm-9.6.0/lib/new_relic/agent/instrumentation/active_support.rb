# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'new_relic/agent/instrumentation/active_support_subscriber'

DependencyDetection.defer do
  named :active_support

  depends_on do
    !NewRelic::Agent.config[:disable_active_support]
  end

  depends_on do
    defined?(ActiveSupport) &&
      !NewRelic::Agent::Instrumentation::ActiveSupportSubscriber.subscribed?
  end

  executes do
    NewRelic::Agent.logger.info('Installing ActiveSupport instrumentation')
  end

  executes do
    ActiveSupport::Notifications.subscribe(/\.active_support$/,
      NewRelic::Agent::Instrumentation::ActiveSupportSubscriber.new)
  end
end
