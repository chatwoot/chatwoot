# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'new_relic/agent/instrumentation/controller_instrumentation'

require_relative 'rack/helpers'
require_relative 'rack/instrumentation'
require_relative 'rack/chain'
require_relative 'rack/prepend'

DependencyDetection.defer do
  named :rack

  depends_on do
    defined?(Rack) && defined?(Rack::Builder)
  end

  executes do
    if use_prepend?
      prepend_instrument Rack::Builder, NewRelic::Agent::Instrumentation::Rack::Prepend
    else
      chain_instrument_target Rack::Builder, NewRelic::Agent::Instrumentation::Rack::Chain
    end
  end
end

DependencyDetection.defer do
  named :puma_rack

  depends_on do
    defined?(Puma::Rack::Builder)
  end

  executes do
    if use_prepend?
      prepend_instrument Puma::Rack::Builder, NewRelic::Agent::Instrumentation::Rack::Prepend
    else
      chain_instrument_target Puma::Rack::Builder, NewRelic::Agent::Instrumentation::Rack::Chain
    end
  end
end

DependencyDetection.defer do
  named :rack_urlmap

  depends_on do
    defined?(Rack) && defined?(Rack::URLMap)
  end

  depends_on do
    NewRelic::Agent::Instrumentation::RackHelpers.middleware_instrumentation_enabled?
  end

  executes do
    if use_prepend?
      prepend_instrument Rack::URLMap, NewRelic::Agent::Instrumentation::Rack::URLMap::Prepend
    else
      chain_instrument_target Rack::URLMap, NewRelic::Agent::Instrumentation::Rack::URLMap::Chain
      NewRelic::Agent::Instrumentation::RackHelpers.instrument_url_map
    end
  end
end

DependencyDetection.defer do
  named :puma_rack_urlmap

  depends_on do
    defined?(Puma::Rack::URLMap)
  end

  depends_on do
    NewRelic::Agent::Instrumentation::RackHelpers.middleware_instrumentation_enabled?
  end

  executes do
    if use_prepend?
      prepend_instrument Puma::Rack::URLMap, NewRelic::Agent::Instrumentation::Rack::URLMap::Prepend
    else
      chain_instrument_target Puma::Rack::URLMap, NewRelic::Agent::Instrumentation::Rack::URLMap::Chain
    end
  end
end
