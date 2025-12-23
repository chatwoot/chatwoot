# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'new_relic/agent/transaction/slowest_sample_buffer'
require 'new_relic/agent/transaction/synthetics_sample_buffer'
require 'new_relic/agent/transaction/trace_builder'

module NewRelic
  module Agent
    # This class contains the logic for recording and storing transaction
    # traces (sometimes referred to as 'transaction samples').
    #
    # A transaction trace is a detailed timeline of the events that happened
    # during the processing of a single transaction, including database calls,
    # template rendering calls, and other instrumented method calls.
    #
    # @api public
    class TransactionSampler
      attr_reader :last_sample

      def initialize
        @sample_buffers = []
        @sample_buffers << NewRelic::Agent::Transaction::SlowestSampleBuffer.new
        @sample_buffers << NewRelic::Agent::Transaction::SyntheticsSampleBuffer.new

        # This lock is used to synchronize access to the @last_sample
        # and related variables. It can become necessary on JRuby or
        # any 'honest-to-god'-multithreaded system
        @samples_lock = Mutex.new

        Agent.config.register_callback(:'transaction_tracer.enabled') do |enabled|
          if enabled
            threshold = Agent.config[:'transaction_tracer.transaction_threshold']
            ::NewRelic::Agent.logger.debug("Transaction tracing threshold is #{threshold} seconds.")
          else
            ::NewRelic::Agent.logger.debug('Transaction traces will not be sent to the New Relic service.')
          end
        end

        Agent.config.register_callback(:'transaction_tracer.record_sql') do |config|
          if config == 'raw'
            ::NewRelic::Agent.logger.warn('Agent is configured to send raw SQL to the service')
          end
        end
      end

      def enabled?
        Agent.config[:'transaction_tracer.enabled']
      end

      def on_finishing_transaction(txn)
        return if !enabled? || txn.ignore_trace?

        @samples_lock.synchronize do
          @last_sample = txn
          store_sample(txn)
          @last_sample
        end
      end

      def store_sample(sample)
        @sample_buffers.each do |sample_buffer|
          sample_buffer.store(sample)
        end
      end

      # Gather transaction traces that we'd like to transmit to the server.
      def harvest!
        return NewRelic::EMPTY_ARRAY unless enabled?

        samples = @samples_lock.synchronize do
          @last_sample = nil
          harvest_from_sample_buffers
        end
        prepare_samples(samples)
      end

      def prepare_samples(samples)
        samples.select do |sample|
          begin
            sample.prepare_to_send!
          rescue => e
            NewRelic::Agent.logger.error('Failed to prepare transaction trace. Error: ', e)
            false
          else
            true
          end
        end
      end

      def merge!(previous)
        @samples_lock.synchronize do
          @sample_buffers.each do |buffer|
            buffer.store_previous(previous)
          end
        end
      end

      def count
        @samples_lock.synchronize do
          samples = @sample_buffers.inject([]) { |all, b| all.concat(b.samples) }
          samples.uniq.size
        end
      end

      def harvest_from_sample_buffers
        # map + flatten hit mocking issues calling to_ary on 1.9.2.  We only
        # want a single level flatten anyway, but, as you probably already
        # know, Ruby 1.8.6 :/
        result = []
        @sample_buffers.each { |buffer| result.concat(buffer.harvest_samples) }
        result.uniq!
        result.map! do |sample|
          if Transaction === sample
            Transaction::TraceBuilder.build_trace(sample)
          else
            sample
          end
        end
      end

      # reset samples without rebooting the web server (used by dev mode)
      def reset!
        @samples_lock.synchronize do
          @last_sample = nil
          @sample_buffers.each { |sample_buffer| sample_buffer.reset! }
        end
      end
    end
  end
end
