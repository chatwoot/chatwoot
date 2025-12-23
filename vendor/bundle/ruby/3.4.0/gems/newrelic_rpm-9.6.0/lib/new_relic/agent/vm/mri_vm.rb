# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'thread'
require 'new_relic/agent/vm/snapshot'

module NewRelic
  module Agent
    module VM
      class MriVM
        def snapshot
          snap = Snapshot.new
          gather_stats(snap)
          snap
        end

        def gather_stats(snap)
          gather_gc_stats(snap)
          gather_ruby_vm_stats(snap)
          gather_thread_stats(snap)
          gather_gc_time(snap)
        end

        def gather_gc_stats(snap)
          gather_gc_runs(snap) if supports?(:gc_runs)
          gather_derived_stats(snap) if GC.respond_to?(:stat)
        end

        def gather_gc_runs(snap)
          snap.gc_runs = GC.count
        end

        def gather_derived_stats(snap)
          stat = GC.stat
          snap.total_allocated_object = derive_from_gc_stats(%i[total_allocated_objects total_allocated_object], stat)
          snap.major_gc_count = derive_from_gc_stats(:major_gc_count, stat)
          snap.minor_gc_count = derive_from_gc_stats(:minor_gc_count, stat)
          snap.heap_live = derive_from_gc_stats(%i[heap_live_slots heap_live_slot heap_live_num], stat)
          snap.heap_free = derive_from_gc_stats(%i[heap_free_slots heap_free_slot heap_free_num], stat)
        end

        def derive_from_gc_stats(keys, stat)
          Array(keys).each do |key|
            value = stat[key]
            return value if value
          end
          nil
        end

        def gather_gc_time(snap)
          return unless supports?(:gc_total_time)

          snap.gc_total_time = NewRelic::Agent.instance.monotonic_gc_profiler.total_time_s
        end

        def gather_ruby_vm_stats(snap)
          if supports?(:method_cache_invalidations)
            snap.method_cache_invalidations = RubyVM.stat[:global_method_state]
          end

          if supports?(:constant_cache_invalidations)
            snap.constant_cache_invalidations = gather_constant_cache_invalidations
          end

          if supports?(:constant_cache_misses)
            snap.constant_cache_misses = gather_constant_cache_misses
          end
        end

        def gather_constant_cache_invalidations
          RubyVM.stat[RUBY_VERSION >= '3.2.0' ? :constant_cache_invalidations : :global_constant_state]
        end

        def gather_constant_cache_misses
          RubyVM.stat[:constant_cache_misses]
        end

        def gather_thread_stats(snap)
          snap.thread_count = Thread.list.size
        end

        def supports?(key)
          case key
          when :gc_runs,
            :total_allocated_object,
            :heap_live,
            :heap_free,
            :thread_count,
            :major_gc_count,
            :minor_gc_count,
            :constant_cache_invalidations
            true
          when :gc_total_time
            NewRelic::LanguageSupport.gc_profiler_enabled?
          when :method_cache_invalidations
            RUBY_VERSION < '3.0.0'
          when :constant_cache_misses
            RUBY_VERSION >= '3.2.0'
          else
            false
          end
        end
      end
    end
  end
end
