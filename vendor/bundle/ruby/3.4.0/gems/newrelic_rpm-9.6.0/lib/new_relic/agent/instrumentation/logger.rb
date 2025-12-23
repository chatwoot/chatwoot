# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require_relative 'logger/instrumentation'
require_relative 'logger/chain'
require_relative 'logger/prepend'

DependencyDetection.defer do
  named :logger

  depends_on do
    defined?(Logger) &&
      NewRelic::Agent.config[:'application_logging.enabled']
  end

  executes do
    NewRelic::Agent.logger.info('Installing Logger instrumentation')

    if use_prepend?
      prepend_instrument Logger, NewRelic::Agent::Instrumentation::Logger::Prepend
    else
      chain_instrument NewRelic::Agent::Instrumentation::Logger
    end
  end
end
