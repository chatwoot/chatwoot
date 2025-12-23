# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require_relative 'httpclient/instrumentation'
require_relative 'httpclient/chain'
require_relative 'httpclient/prepend'

DependencyDetection.defer do
  named :httpclient

  HTTPCLIENT_MIN_VERSION = '2.2.0'

  depends_on do
    defined?(HTTPClient) && defined?(HTTPClient::VERSION)
  end

  depends_on do
    minimum_supported_version = Gem::Version.new(HTTPCLIENT_MIN_VERSION)
    current_version = Gem::Version.new(HTTPClient::VERSION)

    current_version >= minimum_supported_version
  end

  executes do
    NewRelic::Agent.logger.info('Installing HTTPClient instrumentation')
    require 'new_relic/agent/distributed_tracing/cross_app_tracing'
    require 'new_relic/agent/http_clients/httpclient_wrappers'
  end

  executes do
    if use_prepend?
      prepend_instrument HTTPClient, NewRelic::Agent::Instrumentation::HTTPClient::Prepend
    else
      chain_instrument NewRelic::Agent::Instrumentation::HTTPClient::Chain
    end
  end
end
