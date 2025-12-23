# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'new_relic/agent/instrumentation/action_dispatch_subscriber'

DependencyDetection.defer do
  named :action_dispatch

  depends_on do
    !NewRelic::Agent.config[:disable_action_dispatch]
  end

  depends_on do
    defined?(ActiveSupport) &&
      defined?(ActionDispatch) &&
      defined?(ActionPack) &&
      ActionPack.respond_to?(:gem_version) &&
      ActionPack.gem_version >= Gem::Version.new('6.0.0') && # notifications for dispatch added in Rails 6
      !NewRelic::Agent::Instrumentation::ActionDispatchSubscriber.subscribed?
  end

  executes do
    NewRelic::Agent.logger.info('Installing ActionDispatch instrumentation')
  end

  executes do
    ActiveSupport::Notifications.subscribe(/\A[^\.]+\.action_dispatch\z/,
      NewRelic::Agent::Instrumentation::ActionDispatchSubscriber.new)
  end
end
