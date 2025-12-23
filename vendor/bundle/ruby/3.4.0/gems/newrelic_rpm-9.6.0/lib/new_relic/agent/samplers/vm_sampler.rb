# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'new_relic/agent/sampler'
require 'new_relic/agent/vm'

module NewRelic
  module Agent
    module Samplers
      class VMSampler < Sampler
        GC_RUNS_METRIC = 'RubyVM/GC/runs'.freeze
        HEAP_LIVE_METRIC = 'RubyVM/GC/heap_live'.freeze
        HEAP_FREE_METRIC = 'RubyVM/GC/heap_free'.freeze
        THREAD_COUNT_METRIC = 'RubyVM/Threads/all'.freeze
        OBJECT_ALLOCATIONS_METRIC = 'RubyVM/GC/total_allocated_object'.freeze
        MAJOR_GC_METRIC = 'RubyVM/GC/major_gc_count'.freeze
        MINOR_GC_METRIC = 'RubyVM/GC/minor_gc_count'.freeze
        METHOD_INVALIDATIONS_METRIC = 'RubyVM/CacheInvalidations/method'.freeze
        CONSTANT_INVALIDATIONS_METRIC = 'RubyVM/CacheInvalidations/constant'.freeze
        CONSTANT_MISSES_METRIC = 'RubyVM/CacheMisses/constant'.freeze

        attr_reader :transaction_count

        named :vm

        def initialize
          @lock = Mutex.new
          @transaction_count = 0
          @last_snapshot = take_snapshot
        end

        def take_snapshot
          NewRelic::Agent::VM.snapshot
        end

        def setup_events(event_listener)
          event_listener.subscribe(:transaction_finished, &method(:on_transaction_finished))
        end

        def on_transaction_finished(*_)
          @lock.synchronize { @transaction_count += 1 }
        end

        def reset_transaction_count
          @lock.synchronize do
            old_count = @transaction_count
            @transaction_count = 0
            old_count
          end
        end

        def record_gc_runs_metric(snapshot, txn_count) # THREAD_LOCAL_ACCESS
          if snapshot.gc_total_time || snapshot.gc_runs
            if snapshot.gc_total_time
              gc_time = snapshot.gc_total_time - @last_snapshot.gc_total_time.to_f
            end
            if snapshot.gc_runs
              gc_runs = snapshot.gc_runs - @last_snapshot.gc_runs
            end
            wall_clock_time = snapshot.taken_at - @last_snapshot.taken_at
            NewRelic::Agent.agent.stats_engine.tl_record_unscoped_metrics(GC_RUNS_METRIC) do |stats|
              stats.call_count += txn_count
              stats.total_call_time += gc_runs if gc_runs
              stats.total_exclusive_time += gc_time if gc_time
              stats.max_call_time = (gc_time.nil? ? 0 : 1)
              stats.sum_of_squares += wall_clock_time
            end
          end
        end

        def record_delta(snapshot, key, metric, txn_count) # THREAD_LOCAL_ACCESS
          value = snapshot.send(key)
          if value
            delta = value - @last_snapshot.send(key)
            NewRelic::Agent.agent.stats_engine.tl_record_unscoped_metrics(metric) do |stats|
              stats.call_count += txn_count
              stats.total_call_time += delta
            end
          end
        end

        def record_gauge_metric(metric_name, value) # THREAD_LOCAL_ACCESS
          NewRelic::Agent.agent.stats_engine.tl_record_unscoped_metrics(metric_name) do |stats|
            stats.call_count = value
            stats.sum_of_squares = 1
          end
        end

        def record_heap_live_metric(snapshot)
          if snapshot.heap_live
            record_gauge_metric(HEAP_LIVE_METRIC, snapshot.heap_live)
          end
        end

        def record_heap_free_metric(snapshot)
          if snapshot.heap_free
            record_gauge_metric(HEAP_FREE_METRIC, snapshot.heap_free)
          end
        end

        def record_thread_count_metric(snapshot)
          if snapshot.thread_count
            record_gauge_metric(THREAD_COUNT_METRIC, snapshot.thread_count)
          end
        end

        def poll
          snap = take_snapshot
          tcount = reset_transaction_count

          record_gc_runs_metric(snap, tcount)
          record_delta(snap, :total_allocated_object, OBJECT_ALLOCATIONS_METRIC, tcount)
          record_delta(snap, :major_gc_count, MAJOR_GC_METRIC, tcount)
          record_delta(snap, :minor_gc_count, MINOR_GC_METRIC, tcount)
          record_delta(snap, :method_cache_invalidations, METHOD_INVALIDATIONS_METRIC, tcount)
          record_delta(snap, :constant_cache_invalidations, CONSTANT_INVALIDATIONS_METRIC, tcount)
          record_delta(snap, :constant_cache_misses, CONSTANT_MISSES_METRIC, tcount)
          record_heap_live_metric(snap)
          record_heap_free_metric(snap)
          record_thread_count_metric(snap)

          @last_snapshot = snap
        end
      end
    end
  end
end
