# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require_relative 'grape/instrumentation'
require_relative 'grape/chain'
require_relative 'grape/prepend'

DependencyDetection.defer do
  # Why not just :grape? newrelic-grape used that name already, and while we're
  # not shipping yet, overloading the name interferes with the plugin.
  @name = :grape_instrumentation
  configure_with :grape

  depends_on do
    defined?(Grape::VERSION) &&
      Gem::Version.new(Grape::VERSION) >= NewRelic::Agent::Instrumentation::Grape::Instrumentation::MIN_VERSION
  end

  depends_on do
    begin
      if defined?(Bundler) && Bundler.rubygems.all_specs.map(&:name).include?('newrelic-grape')
        NewRelic::Agent.logger.info('Not installing New Relic supported Grape instrumentation because the third party newrelic-grape gem is present')
        false
      else
        true
      end
    rescue => e
      NewRelic::Agent.logger.info('Could not determine if third party newrelic-grape gem is installed', e)
      true
    end
  end

  executes do
    NewRelic::Agent::Instrumentation::Grape::Instrumentation.prepare!

    if use_prepend?
      instrumented_class = NewRelic::Agent::Instrumentation::Grape::Instrumentation.instrumented_class
      prepend_instrument instrumented_class, NewRelic::Agent::Instrumentation::Grape::Prepend
    else
      chain_instrument NewRelic::Agent::Instrumentation::Grape::Chain
    end
  end
end
