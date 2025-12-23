# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require_relative 'bunny/instrumentation'
require_relative 'bunny/chain'
require_relative 'bunny/prepend'

DependencyDetection.defer do
  named :bunny

  depends_on do
    defined?(Bunny)
  end

  executes do
    NewRelic::Agent.logger.info('Installing Bunny instrumentation')
    require 'new_relic/agent/distributed_tracing/cross_app_tracing'
    require 'new_relic/agent/messaging'
    require 'new_relic/agent/transaction/message_broker_segment'
  end

  executes do
    if use_prepend?
      prepend_instrument Bunny::Exchange, NewRelic::Agent::Instrumentation::Bunny::Prepend::Exchange
      prepend_instrument Bunny::Queue, NewRelic::Agent::Instrumentation::Bunny::Prepend::Queue
      prepend_instrument Bunny::Consumer, NewRelic::Agent::Instrumentation::Bunny::Prepend::Consumer
    else
      chain_instrument NewRelic::Agent::Instrumentation::Bunny::Chain
    end
  end
end
