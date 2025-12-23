# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic
  module Agent
    module DistributedTracing
      class Monitor < InboundRequestMonitor
        def on_finished_configuring(events)
          return unless NewRelic::Agent.config[:'distributed_tracing.enabled']

          events.subscribe(:before_call, &method(:on_before_call))
        end

        def on_before_call(request)
          unless NewRelic::Agent.config[:'distributed_tracing.enabled']
            NewRelic::Agent.logger.warn('Not configured to accept distributed trace headers')
            return
          end

          return unless txn = Tracer.current_transaction

          txn.distributed_tracer.accept_incoming_request(request)
        end
      end
    end
  end
end
