# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require_relative 'rake/instrumentation'
require_relative 'rake/chain'
require_relative 'rake/prepend'

DependencyDetection.defer do
  # Why not :rake? newrelic-rake used that name, so avoid conflicting
  @name = :rake_instrumentation
  configure_with :rake

  depends_on { defined?(Rake) && defined?(Rake::VERSION) }
  depends_on { Gem::Version.new(Rake::VERSION) >= Gem::Version.new('10.0.0') }
  depends_on { NewRelic::Agent.config[:'rake.tasks'].any? }
  depends_on { NewRelic::Agent::Instrumentation::Rake.safe_from_third_party_gem? }

  executes do
    NewRelic::Agent.logger.info('Installing Rake instrumentation')
    NewRelic::Agent.logger.debug("Instrumenting Rake tasks: #{NewRelic::Agent.config[:'rake.tasks']}")
  end

  executes do
    if use_prepend?
      prepend_instrument Rake::Task, NewRelic::Agent::Instrumentation::Rake::Prepend
    else
      chain_instrument NewRelic::Agent::Instrumentation::Rake::Chain
    end
  end
end
