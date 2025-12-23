# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require_relative 'async_http/instrumentation'
require_relative 'async_http/chain'
require_relative 'async_http/prepend'

DependencyDetection.defer do
  named :async_http

  depends_on do
    defined?(Async::HTTP) && Gem::Version.new(Async::HTTP::VERSION) >= Gem::Version.new('0.59.0')
  end

  executes do
    NewRelic::Agent.logger.info('Installing async_http instrumentation')

    require 'async/http/internet'
    if use_prepend?
      prepend_instrument Async::HTTP::Internet, NewRelic::Agent::Instrumentation::AsyncHttp::Prepend
    else
      chain_instrument NewRelic::Agent::Instrumentation::AsyncHttp::Chain
    end
  end
end
