# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require_relative 'net_http/chain'
require_relative 'net_http/prepend'

DependencyDetection.defer do
  named :net_http

  depends_on do
    defined?(Net) && defined?(Net::HTTP)
  end

  executes do
    NewRelic::Agent.logger.info('Installing Net:HTTP Wrappers')
    require 'new_relic/agent/http_clients/net_http_wrappers'
  end

  # Airbrake uses method chaining on Net::HTTP in versions < 10.0.2 (10.0.2 updated to prepend for Net:HTTP)
  conflicts_with_prepend do
    defined?(Airbrake) && defined?(Airbrake::AIRBRAKE_VERSION) && Gem::Version.create(Airbrake::AIRBRAKE_VERSION) < Gem::Version.create('10.0.2')
  end

  conflicts_with_prepend do
    defined?(ScoutApm)
  end

  conflicts_with_prepend do
    defined?(Rack::MiniProfiler) && !defined?(Rack::MINI_PROFILER_PREPEND_NET_HTTP_PATCH)
  end

  conflicts_with_prepend do
    source_location_for(Net::HTTP, 'request') =~ /airbrake|profiler/i
  end

  executes do
    if use_prepend?
      prepend_instrument Net::HTTP, NewRelic::Agent::Instrumentation::NetHTTP::Prepend
    else
      chain_instrument NewRelic::Agent::Instrumentation::NetHTTP::Chain
    end
  end
end
