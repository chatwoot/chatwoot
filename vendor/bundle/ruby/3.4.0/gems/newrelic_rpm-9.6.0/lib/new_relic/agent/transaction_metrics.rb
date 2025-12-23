# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

# This class represents a set of metrics that were recorded during a single
# transaction. Since the name of the transaction is not known until its end, we
# don't save explicit scopes with these metrics, we just keep separate
# collections of scoped and unscoped metrics.

module NewRelic
  module Agent
    class TransactionMetrics
      DEFAULT_PROC = proc { |hash, name| hash[name] = NewRelic::Agent::Stats.new }

      def initialize
        @lock = Mutex.new
        @unscoped = Hash.new(&DEFAULT_PROC)
        @scoped = Hash.new(&DEFAULT_PROC)
      end

      # As a general rule, when recording a scoped metric, the corresponding
      # unscoped metric should always be recorded as well.
      #
      # As an optimization, scoped metrics are representated within this class
      # only by their entries in the @scoped Hash, and it's up to clients to
      # propagate them into unscoped metrics as well when instances of this
      # class are merged into the global metric store.
      #
      def record_scoped_and_unscoped(names, value = nil, aux = nil, &blk)
        _record_metrics(names, value, aux, @scoped, &blk)
      end

      def record_unscoped(names, value = nil, aux = nil, &blk)
        _record_metrics(names, value, aux, @unscoped, &blk)
      end

      def has_key?(key)
        @unscoped.has_key?(key)
      end

      def [](key)
        @unscoped[key]
      end

      def each_unscoped
        @lock.synchronize { @unscoped.each { |name, stats| yield(name, stats) } }
      end

      def each_scoped
        @lock.synchronize { @scoped.each { |name, stats| yield(name, stats) } }
      end

      def _record_metrics(names, value, aux, target, &blk)
        # This looks dumb, but we're avoiding an extra Array allocation.
        case names
        when Array
          names.each do |name|
            @lock.synchronize { target[name].record(value, aux, &blk) }
          end
        else
          @lock.synchronize { target[names].record(value, aux, &blk) }
        end
      end
    end
  end
end
