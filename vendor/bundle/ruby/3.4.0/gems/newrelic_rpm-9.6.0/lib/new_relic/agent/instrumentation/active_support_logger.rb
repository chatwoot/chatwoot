# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require_relative 'active_support_logger/instrumentation'
require_relative 'active_support_logger/chain'
require_relative 'active_support_logger/prepend'

DependencyDetection.defer do
  named :active_support_logger

  depends_on do
    defined?(ActiveSupport::Logger) && defined?(ActiveSupport::Logger.broadcast)
  end

  executes do
    NewRelic::Agent.logger.info('Installing ActiveSupport::Logger instrumentation')

    if use_prepend?
      # the only method currently instrumented is a class method
      prepend_instrument ActiveSupport::Logger.singleton_class, NewRelic::Agent::Instrumentation::ActiveSupportLogger::Prepend
    else
      chain_instrument NewRelic::Agent::Instrumentation::ActiveSupportLogger::Chain
    end
  end
end
