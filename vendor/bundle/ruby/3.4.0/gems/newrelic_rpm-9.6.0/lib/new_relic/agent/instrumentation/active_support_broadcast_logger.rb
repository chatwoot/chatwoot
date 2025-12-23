# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require_relative 'active_support_broadcast_logger/instrumentation'
require_relative 'active_support_broadcast_logger/chain'
require_relative 'active_support_broadcast_logger/prepend'

DependencyDetection.defer do
  named :'active_support_broadcast_logger'

  depends_on { defined?(ActiveSupport::BroadcastLogger) }

  executes do
    NewRelic::Agent.logger.info('Installing ActiveSupport::BroadcastLogger instrumentation')

    if use_prepend?
      prepend_instrument ActiveSupport::BroadcastLogger, NewRelic::Agent::Instrumentation::ActiveSupportBroadcastLogger::Prepend
    else
      chain_instrument NewRelic::Agent::Instrumentation::ActiveSupportBroadcastLogger::Chain
    end
  end
end
