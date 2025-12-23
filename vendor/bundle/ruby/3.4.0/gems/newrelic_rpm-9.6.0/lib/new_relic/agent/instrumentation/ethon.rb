# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require_relative 'ethon/instrumentation'
require_relative 'ethon/chain'
require_relative 'ethon/prepend'

DependencyDetection.defer do
  named :ethon

  # If Ethon is being used as a dependency of Typhoeus, allow the Typhoeus
  # instrumentation to handle everything. Otherwise each external network call
  # will confusingly result in "Ethon" segments duplicating the information
  # already provided by "Typhoeus" segments.
  depends_on do
    !defined?(Typhoeus)
  end

  depends_on do
    defined?(Ethon) && Gem::Version.new(Ethon::VERSION) >= Gem::Version.new('0.12.0')
  end

  executes do
    NewRelic::Agent.logger.info('Installing ethon instrumentation')
  end

  executes do
    if use_prepend?
      # NOTE: by default prepend_instrument will go with the module name that
      #       precedes 'Prepend' (so 'Easy' and 'Multi'), but we want to use
      #       'Ethon::Easy' and 'Ethon::Multi' so 3rd argument is supplied
      prepend_instrument Ethon::Easy, NewRelic::Agent::Instrumentation::Ethon::Easy::Prepend, Ethon::Easy.name
      prepend_instrument Ethon::Multi, NewRelic::Agent::Instrumentation::Ethon::Multi::Prepend, Ethon::Multi.name
    else
      chain_instrument NewRelic::Agent::Instrumentation::Ethon::Chain
    end
  end
end
