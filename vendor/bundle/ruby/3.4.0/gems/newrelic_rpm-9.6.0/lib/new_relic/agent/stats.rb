# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic
  module Agent
    class Stats
      SKIP_MARSHALLING = [:@lock]

      attr_accessor :call_count
      attr_accessor :min_call_time
      attr_accessor :max_call_time
      attr_accessor :total_call_time
      attr_accessor :total_exclusive_time
      attr_accessor :sum_of_squares

      def initialize
        @lock = Mutex.new
        reset
      end

      def reset
        @call_count = 0
        @total_call_time = 0.0
        @total_exclusive_time = 0.0
        @min_call_time = 0.0
        @max_call_time = 0.0
        @sum_of_squares = 0.0
      end

      def is_reset?
        call_count == 0 && total_call_time == 0.0 && total_exclusive_time == 0.0
      end

      def merge(other_stats)
        stats = self.clone
        stats.merge!(other_stats)
      end

      def merge!(other)
        @lock.synchronize do
          @min_call_time = other.min_call_time if min_time_less?(other)
          @max_call_time = other.max_call_time if other.max_call_time > max_call_time
          @total_call_time += other.total_call_time
          @total_exclusive_time += other.total_exclusive_time
          @sum_of_squares += other.sum_of_squares
          @call_count += other.call_count
        end
        self
      end

      def hash_merge(hash)
        @call_count = hash[:count] if hash[:count]
        @total_call_time = hash[:total] if hash[:total]
        @total_exclusive_time = hash[:total] if hash[:total]
        @min_call_time = hash[:min] if hash[:min]
        @max_call_time = hash[:max] if hash[:max]
        @sum_of_squares = hash[:sum_of_squares] if hash[:sum_of_squares]
        self
      end

      def to_json(*_)
        {
          'call_count' => call_count.to_i,
          'min_call_time' => min_call_time.to_f,
          'max_call_time' => max_call_time.to_f,
          'total_call_time' => total_call_time.to_f,
          'total_exclusive_time' => total_exclusive_time.to_f,
          'sum_of_squares' => sum_of_squares.to_f
        }.to_json(*_)
      end

      def to_s
        "[#{'%2i' % call_count.to_i} calls #{'%.4f' % total_call_time.to_f}s / #{'%.4f' % total_exclusive_time.to_f}s ex]"
      end

      def record(value = nil, aux = nil, &blk)
        if blk
          yield(self)
        else
          case value
          when Numeric
            aux ||= value
            self.record_data_point(value, aux)
          when :apdex_s, :apdex_t, :apdex_f
            self.record_apdex(value, aux)
          when NewRelic::Agent::Stats
            self.merge!(value)
          end
        end
      end

      # record a single data point into the statistical gatherer.  The gatherer
      # will aggregate all data points collected over a specified period and upload
      # its data to the NewRelic server
      def record_data_point(value, exclusive_time = value)
        @lock.synchronize do
          @call_count += 1
          @total_call_time += value
          @min_call_time = value if value < @min_call_time || @call_count == 1
          @max_call_time = value if value > @max_call_time
          @total_exclusive_time += exclusive_time

          @sum_of_squares += (value * value)
        end
        self
      end

      alias trace_call record_data_point

      # increments the call_count by one
      def increment_count(value = 1)
        @lock.synchronize { @call_count += value }
      end

      # Concerned about implicit usage of inspect relying on stats format, so
      # putting back a version to get full inspection as separate method
      def inspect_full
        variables = instance_variables.map do |ivar|
          "#{ivar.to_s}=#{instance_variable_get(ivar).inspect}"
        end.join(' ')
        "#<NewRelic::Agent::Stats #{variables}>"
      end

      def ==(other)
        other.class == self.class &&
          (
            @min_call_time == other.min_call_time &&
            @max_call_time == other.max_call_time &&
            @total_call_time == other.total_call_time &&
            @total_exclusive_time == other.total_exclusive_time &&
            @sum_of_squares == other.sum_of_squares &&
            @call_count == other.call_count
          )
      end

      # Apdex-related accessors
      alias_method :apdex_s, :call_count
      alias_method :apdex_t, :total_call_time
      alias_method :apdex_f, :total_exclusive_time

      def record_apdex(bucket, apdex_t)
        @lock.synchronize do
          case bucket
          when :apdex_s then @call_count += 1
          when :apdex_t then @total_call_time += 1
          when :apdex_f then @total_exclusive_time += 1
          end
          if apdex_t
            @min_call_time = apdex_t
            @max_call_time = apdex_t
          else
            ::NewRelic::Agent.logger.warn("Attempted to set apdex_t to #{apdex_t.inspect}, backtrace = #{caller.join("\n")}")
          end
        end
      end

      # Override marshalling methods to exclude @lock from being included in marshalled data
      def marshal_dump
        instance_variables.each_with_object({}) do |name, instance_copy|
          next if SKIP_MARSHALLING.include?(name)

          instance_copy[name] = instance_variable_get(name)
        end
      end

      def marshal_load(marshalled_data)
        marshalled_data.each do |name, value|
          instance_variable_set(name, value) unless SKIP_MARSHALLING.include?(name)
        end
        # since the lock is excluded when marshalling, create a new lock when loading marshalled data
        @lock = Mutex.new
      end

      protected

      def min_time_less?(other)
        (other.min_call_time < min_call_time && other.call_count > 0) || call_count == 0
      end
    end
  end
end
