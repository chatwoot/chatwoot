# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require_relative 'thread/chain'
require_relative 'thread/prepend'

DependencyDetection.defer do
  named :thread

  executes do
    NewRelic::Agent.logger.info('Installing Thread Instrumentation')

    if use_prepend?
      prepend_instrument Thread, NewRelic::Agent::Instrumentation::MonitoredThread::Prepend
    else
      chain_instrument NewRelic::Agent::Instrumentation::MonitoredThread::Chain
    end
  end
end
