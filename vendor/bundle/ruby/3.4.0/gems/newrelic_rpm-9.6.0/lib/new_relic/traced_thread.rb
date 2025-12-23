# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic
  #
  # This class allows the current transaction to be passed to a Thread so that nested segments can be created from the operations performed within the Thread's block.
  # To have the New Relic Ruby agent automatically trace all of your applications threads,
  # enable the +instrumentation.thread.tracing+ configuration option in your newrelic.yml.
  #
  # Note: disabling the configuration option +instrumentation.thread+ while using this class can cause incorrectly nested spans.
  #
  # @api public
  class TracedThread < Thread
    #
    # Creates a new Thread whose work will be traced by New Relic.
    # Use this class as a replacement for the native Thread class.
    # Example: Instead of using +Thread.new+, use:
    #
    #     NewRelic::TracedThread.new { execute_some_code }
    #
    # @api public
    def initialize(*args, &block)
      NewRelic::Agent.record_api_supportability_metric(:traced_thread)
      traced_block = create_traced_block(&block)
      super(*args, &traced_block)
    end

    def create_traced_block(&block)
      return block if NewRelic::Agent.config[:'instrumentation.thread.tracing'] # if this is on, don't double trace

      NewRelic::Agent::Tracer.thread_block_with_current_transaction(
        segment_name: 'Ruby/TracedThread',
        &block
      )
    end
  end
end
