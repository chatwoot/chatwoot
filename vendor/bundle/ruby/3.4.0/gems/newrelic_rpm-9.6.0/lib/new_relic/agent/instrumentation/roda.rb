# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require_relative 'roda/instrumentation'
require_relative 'roda/roda_transaction_namer'
require_relative 'roda/ignorer'

DependencyDetection.defer do
  named :roda

  depends_on do
    defined?(Roda) &&
      Gem::Version.new(Roda::RodaVersion) >= Gem::Version.new('3.19.0') &&
      Roda::RodaPlugins::Base::ClassMethods.private_method_defined?(:build_rack_app) &&
      Roda::RodaPlugins::Base::InstanceMethods.method_defined?(:_roda_handle_main_route)
  end

  executes do
    require_relative '../../rack/agent_hooks'
    require_relative '../../rack/browser_monitoring'

    NewRelic::Agent.logger.info('Installing Roda instrumentation')

    if use_prepend?
      require_relative 'roda/prepend'
      prepend_instrument Roda.singleton_class, NewRelic::Agent::Instrumentation::Roda::Build::Prepend
      prepend_instrument Roda, NewRelic::Agent::Instrumentation::Roda::Prepend
    else
      require_relative 'roda/chain'
      chain_instrument NewRelic::Agent::Instrumentation::Roda::Build::Chain
      chain_instrument NewRelic::Agent::Instrumentation::Roda::Chain
    end
    Roda.class_eval { extend NewRelic::Agent::Instrumentation::Roda::Ignorer }
  end
end
