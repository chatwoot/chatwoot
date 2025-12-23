# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

# This is the initialization for the New Relic Ruby Agent when used as
# a plugin
require 'new_relic/control'

# If you are having problems seeing data, be sure and check the
# newrelic_agent.log files in the log directory of your application
#
# If you can't find any log files and you don't see anything in your
# application log files please visit support.newrelic.com.

# Initializer for the NewRelic Ruby Agent

# After version 2.0 of Rails we can access the configuration directly.
# We need it to add dev mode routes after initialization finished.

begin
  current_config = if defined?(config)
    config
  elsif defined?(Rails.configuration)
    Rails.configuration
  end

  NewRelic::Control.instance.init_plugin(:config => current_config)
rescue => e
  NewRelic::Agent.logger.error('Error initializing New Relic plugin. Agent is disabled.', e)
end
