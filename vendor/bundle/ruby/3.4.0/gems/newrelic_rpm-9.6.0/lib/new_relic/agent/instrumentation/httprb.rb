# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require_relative 'httprb/instrumentation'
require_relative 'httprb/chain'
require_relative 'httprb/prepend'

DependencyDetection.defer do
  named :httprb

  depends_on do
    defined?(HTTP) && defined?(HTTP::Client)
  end

  executes do
    NewRelic::Agent.logger.info('Installing http.rb Wrappers')
    require 'new_relic/agent/distributed_tracing/cross_app_tracing'
    require 'new_relic/agent/http_clients/http_rb_wrappers'
  end

  executes do
    if use_prepend?
      prepend_instrument HTTP::Client, NewRelic::Agent::Instrumentation::HTTPrb::Prepend
    else
      chain_instrument NewRelic::Agent::Instrumentation::HTTPrb::Chain
    end
  end
end
