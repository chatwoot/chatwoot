# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

# This is a helper file that will allow apps using ActiveSupport without Rails
# to still leverage all ActiveSupport based instrumentation functionality
# offered by the agent that would otherwise be gated by the detection of Rails.

# ActiveSupport notifications custom events
if !defined?(Rails) && defined?(ActiveSupport::Notifications) && defined?(ActiveSupport::IsolatedExecutionState)
  require_relative 'rails_notifications/custom_events'
end
