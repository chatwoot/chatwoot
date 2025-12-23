# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic::Agent::Instrumentation
  module Padrino
    INSTRUMENTATION_NAME = NewRelic::Agent.base_name(name)

    def invoke_route_with_tracing(*args)
      NewRelic::Agent.record_instrumentation_invocation(INSTRUMENTATION_NAME)

      begin
        env['newrelic.last_route'] = args[0].original_path
      rescue => e
        ::NewRelic::Agent.logger.debug('Failed determining last route in Padrino', e)
      end

      begin
        txn_name = ::NewRelic::Agent::Instrumentation::Sinatra::TransactionNamer.transaction_name_for_route(env, request)
        unless txn_name.nil?
          ::NewRelic::Agent::Transaction.set_default_transaction_name(
            "#{self.class.name}/#{txn_name}", :sinatra
          )
        end
      rescue => e
        ::NewRelic::Agent.logger.debug('Failed during invoke_route to set transaction name', e)
      end

      yield
    end
  end
end
