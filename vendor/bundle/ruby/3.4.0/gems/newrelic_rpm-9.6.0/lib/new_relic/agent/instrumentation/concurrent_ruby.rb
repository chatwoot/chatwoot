# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require_relative 'concurrent_ruby/instrumentation'
require_relative 'concurrent_ruby/chain'
require_relative 'concurrent_ruby/prepend'

DependencyDetection.defer do
  named :'concurrent_ruby'

  depends_on do
    defined?(Concurrent) &&
      Gem::Version.new(Concurrent::VERSION) >= Gem::Version.new('1.1.5')
  end

  executes do
    NewRelic::Agent.logger.info('Installing concurrent-ruby instrumentation')

    if use_prepend?
      prepend_instrument(Concurrent::ThreadPoolExecutor, NewRelic::Agent::Instrumentation::ConcurrentRuby::Prepend)

      [Concurrent::Promises.const_get(:'InternalStates')::Rejected,
        Concurrent::Promises.const_get(:'InternalStates')::PartiallyRejected].each do |klass|
          klass.prepend(NewRelic::Agent::Instrumentation::ConcurrentRuby::ErrorPrepend)
        end
    else
      chain_instrument NewRelic::Agent::Instrumentation::ConcurrentRuby::Chain
    end
  end
end
