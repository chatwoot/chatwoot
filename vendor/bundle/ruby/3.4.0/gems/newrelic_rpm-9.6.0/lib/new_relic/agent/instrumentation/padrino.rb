# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

# Our Padrino instrumentation relies heavily on the fact that Padrino is
# built on Sinatra. Although it wires up a lot of its own routing logic,
# we only need to patch into Padrino's dispatch to get things started.
#
# Parts of the Sinatra instrumentation (such as the TransactionNamer) are
# aware of Padrino as a potential target in areas where both Sinatra and
# Padrino run through the same code.

require_relative 'sinatra'
require_relative 'padrino/chain'
require_relative 'padrino/instrumentation'
require_relative 'padrino/prepend'

DependencyDetection.defer do
  @name = :padrino
  configure_with :sinatra

  depends_on { defined?(Padrino) && defined?(Padrino::Routing::InstanceMethods) }

  executes do
    NewRelic::Agent.logger.info('Installing Padrino instrumentation')
    if use_prepend?
      prepend_instrument Padrino::Application, NewRelic::Agent::Instrumentation::PadrinoTracer::Prepend
    else
      chain_instrument NewRelic::Agent::Instrumentation::PadrinoTracer::Chain
    end
  end
end
