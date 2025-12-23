# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require_relative 'tilt/instrumentation'
require_relative 'tilt/chain'
require_relative 'tilt/prepend'

DependencyDetection.defer do
  named :tilt

  depends_on { defined?(Tilt) }

  executes do
    NewRelic::Agent.logger.info('Installing Tilt instrumentation')
  end

  executes do
    if use_prepend?
      prepend_instrument Tilt::Template, NewRelic::Agent::Instrumentation::Tilt::Prepend
    else
      chain_instrument NewRelic::Agent::Instrumentation::Tilt::Chain
    end
  end
end
