# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require_relative 'curb/chain'
require_relative 'curb/prepend'

DependencyDetection.defer do
  named :curb

  CURB_MIN_VERSION = Gem::Version.new('0.8.1')

  depends_on do
    defined?(Curl) && defined?(Curl::CURB_VERSION) &&
      Gem::Version.new(Curl::CURB_VERSION) >= CURB_MIN_VERSION
  end

  executes do
    NewRelic::Agent.logger.info('Installing Curb instrumentation')
    require 'new_relic/agent/distributed_tracing/cross_app_tracing'
    require 'new_relic/agent/http_clients/curb_wrappers'
  end

  executes do
    if use_prepend?
      prepend_instrument Curl::Easy, NewRelic::Agent::Instrumentation::Curb::Easy::Prepend
      prepend_instrument Curl::Multi, NewRelic::Agent::Instrumentation::Curb::Multi::Prepend
    else
      chain_instrument NewRelic::Agent::Instrumentation::Curb::Chain
    end
  end
end
