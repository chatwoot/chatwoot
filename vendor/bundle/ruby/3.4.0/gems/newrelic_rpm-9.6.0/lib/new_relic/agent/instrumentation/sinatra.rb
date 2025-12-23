# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require_relative 'sinatra/transaction_namer'
require_relative 'sinatra/ignorer'
require_relative 'sinatra/instrumentation'
require_relative 'sinatra/chain'
require_relative 'sinatra/prepend'

DependencyDetection.defer do
  named :sinatra

  depends_on { defined?(Sinatra) && defined?(Sinatra::Base) }
  depends_on { Sinatra::Base.private_method_defined?(:dispatch!) }
  depends_on { Sinatra::Base.private_method_defined?(:process_route) }
  depends_on { Sinatra::Base.private_method_defined?(:route_eval) }

  executes do
    NewRelic::Agent.logger.info('Installing Sinatra instrumentation')
  end

  executes do
    if use_prepend?
      prepend_instrument Sinatra::Base, NewRelic::Agent::Instrumentation::Sinatra::Prepend
    else
      chain_instrument NewRelic::Agent::Instrumentation::Sinatra::Chain
    end

    Sinatra::Base.class_eval { register NewRelic::Agent::Instrumentation::Sinatra::Ignorer }
    Sinatra.module_eval { register NewRelic::Agent::Instrumentation::Sinatra::Ignorer }
  end

  executes do
    # These requires are inside an executes block because they require rack, and
    # we can't be sure that rack is available when this file is first required.
    require 'new_relic/rack/agent_hooks'
    require 'new_relic/rack/browser_monitoring'
    if use_prepend?
      prepend_instrument Sinatra::Base.singleton_class, NewRelic::Agent::Instrumentation::Sinatra::Build::Prepend
    else
      chain_instrument NewRelic::Agent::Instrumentation::Sinatra::Build::Chain
    end
  end

  executes do
    next unless Gem::Version.new(Sinatra::VERSION) < Gem::Version.new('2.0.0')

    deprecation_msg = 'The Ruby Agent is dropping support for Sinatra versions below 2.0.0 ' \
      'in version 9.0.0. Please upgrade your Sinatra version to continue receiving full compatibility. ' \

    NewRelic::Agent.logger.log_once(
      :warn,
      :deprecated_sinatra_version,
      deprecation_msg
    )
  end
end
