# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'new_relic/agent/instrumentation/action_mailbox_subscriber'

DependencyDetection.defer do
  named :action_mailbox

  depends_on do
    !NewRelic::Agent.config[:disable_action_mailbox]
  end

  depends_on do
    defined?(ActiveSupport) &&
      defined?(ActionMailbox) &&
      ActionMailbox.respond_to?(:gem_version) && # 'require "action_mailbox"' doesn't require version...
      ActionMailbox.gem_version >= Gem::Version.new('7.1.0.alpha') && # notifications added in Rails 7.1
      !NewRelic::Agent::Instrumentation::ActionMailboxSubscriber.subscribed?
  end

  executes do
    NewRelic::Agent.logger.info('Installing ActionMailbox instrumentation')
  end

  executes do
    ActiveSupport::Notifications.subscribe(/\A[^\.]+\.action_mailbox\z/,
      NewRelic::Agent::Instrumentation::ActionMailboxSubscriber.new)
  end
end
