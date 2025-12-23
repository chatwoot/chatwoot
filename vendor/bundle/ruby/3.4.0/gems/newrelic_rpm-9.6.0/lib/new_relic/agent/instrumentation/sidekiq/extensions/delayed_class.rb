# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

# TODO: remove this class once Sidekiq v6 is no longer supported.
#       Delayed extensions are disabled by default in Sidekiq 5 and 6 and
#       were removed entirely in Sidekiq 7.
#
#       see https://github.com/mperham/sidekiq/issues/5076 for the discussion
#       of the removal, which includes mentions of alternatives
if defined?(Sidekiq::VERSION) && Sidekiq::VERSION < '7.0.0'
  class Sidekiq::Extensions::DelayedClass
    def newrelic_trace_args(msg, queue)
      (target, method_name, _args) = if YAML.respond_to?(:unsafe_load)
        YAML.unsafe_load(msg['args'][0])
      else
        YAML.load(msg['args'][0])
      end

      {
        :name => method_name,
        :class_name => target.name,
        :category => 'OtherTransaction/SidekiqJob'
      }
    rescue => e
      NewRelic::Agent.logger.error('Failure during deserializing YAML for Sidekiq::Extensions::DelayedClass', e)
      NewRelic::Agent::Instrumentation::Sidekiq::Server.default_trace_args(msg)
    end
  end
end
