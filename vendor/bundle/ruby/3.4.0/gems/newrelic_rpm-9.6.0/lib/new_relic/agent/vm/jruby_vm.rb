# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'thread'
require 'new_relic/agent/vm/snapshot'

module NewRelic
  module Agent
    module VM
      class JRubyVM
        def snapshot
          snap = Snapshot.new
          gather_stats(snap)
          snap
        end

        def gather_stats(snap)
          if supports?(:gc_runs)
            gc_stats = GC.stat
            snap.gc_runs = gc_stats[:count]
          end

          snap.thread_count = Thread.list.size
        end

        def supports?(key)
          case key
          when :gc_runs, :thread_count
            true
          else
            false
          end
        end
      end
    end
  end
end
