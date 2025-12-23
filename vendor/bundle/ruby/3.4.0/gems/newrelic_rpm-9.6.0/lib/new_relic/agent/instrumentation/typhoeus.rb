# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require_relative 'typhoeus/instrumentation'
require_relative 'typhoeus/chain'
require_relative 'typhoeus/prepend'

DependencyDetection.defer do
  named :typhoeus

  depends_on do
    defined?(Typhoeus) && defined?(Typhoeus::VERSION)
  end

  depends_on do
    NewRelic::Agent::Instrumentation::Typhoeus.is_supported_version?
  end

  executes do
    NewRelic::Agent.logger.info('Installing Typhoeus instrumentation')
    require 'new_relic/agent/distributed_tracing/cross_app_tracing'
    require 'new_relic/agent/http_clients/typhoeus_wrappers'
  end

  # Basic request tracing
  executes do
    Typhoeus.before do |request|
      NewRelic::Agent::Instrumentation::Typhoeus.trace(request)

      # Ensure that we always return a truthy value from the before block,
      # otherwise Typhoeus will bail out of the instrumentation.
      true
    end
  end

  # Apply single TT node for Hydra requests until async support
  executes do
    if use_prepend?
      prepend_instrument Typhoeus::Hydra, NewRelic::Agent::Instrumentation::Typhoeus::Prepend
    else
      chain_instrument NewRelic::Agent::Instrumentation::Typhoeus::Chain
    end
  end
end
