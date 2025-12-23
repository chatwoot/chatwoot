# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

# frozen_string_literal: true

module ElasticAPM
  # @api private
  module Metrics
    def self.new(config, &block)
      Registry.new(config, &block)
    end

    def self.platform
      @platform ||= Gem::Platform.local.os.to_sym
    end

    def self.os
      @os ||= RbConfig::CONFIG.fetch('host_os', 'unknown').to_sym
    end

    # @api private
    class Registry
      include Logging

      def initialize(config, &block)
        @config = config
        @callback = block
        @sets = nil
      end

      attr_reader :config, :sets, :callback

      def start
        unless config.collect_metrics?
          debug 'Skipping metrics'
          return
        end

        debug 'Starting metrics'

        # Only set the @sets once, in case we stop
        # and start again.
        if @sets.nil?
          sets = {
            system: CpuMemSet,
            vm: VMSet,
            breakdown: BreakdownSet,
            transaction: TransactionSet
          }
          if defined?(JVMSet)
            debug "Enabling JVM metrics collection"
            sets[:jvm] = JVMSet
          end

          @sets = sets.each_with_object({}) do |(key, kls), _sets_|
            debug "Adding metrics collector '#{kls}'"
            _sets_[key] = kls.new(config)
          end
        end

        @timer_task = Concurrent::TimerTask.execute(
          run_now: true,
          execution_interval: config.metrics_interval
        ) do
          begin
            debug 'Collecting metrics'
            collect_and_send
            true
          rescue StandardError => e
            error 'Error while collecting metrics: %e', e.inspect
            debug { e.backtrace.join("\n") }
            false
          end
        end

        @running = true
      end

      def stop
        return unless running?

        debug 'Stopping metrics'

        @timer_task.shutdown
        @running = false
      end

      def running?
        !!@running
      end

      def handle_forking!
        # Note that ideally we would be able to check if the @timer_task died
        # and restart it. You can't simply check @timer_task.running? because
        # it will only return the state of the TimerTask, not whether the
        # internal thread used to manage the execution interval has died.
        # This is a limitation of the Concurrent::TimerTask object.
        # Therefore, our only option when forked is to stop and start.
        # ~estolfo
        stop
        start
      end

      def get(key)
        sets.fetch(key)
      end

      def collect_and_send
        return unless @config.recording?
        metricsets = collect
        metricsets.compact!
        metricsets.each do |m|
          callback.call(m)
        end
      end

      def collect
        sets.each_value.each_with_object([]) do |set, arr|
          samples = set.collect
          next unless samples
          arr.concat(samples)
        end
      end
    end
  end
end

require 'elastic_apm/metricset'

require 'elastic_apm/metrics/metric'
require 'elastic_apm/metrics/set'

require 'elastic_apm/metrics/cpu_mem_set'
require 'elastic_apm/metrics/vm_set'
require 'elastic_apm/metrics/jvm_set' if defined?(JRUBY_VERSION)
require 'elastic_apm/metrics/span_scoped_set'
require 'elastic_apm/metrics/transaction_set'
require 'elastic_apm/metrics/breakdown_set'
