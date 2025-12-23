# frozen_string_literal: true

require "concurrent"

module Sidekiq
  module Metrics
    # This is the only dependency on concurrent-ruby in Sidekiq but it's
    # mandatory for thread-safety until MRI supports atomic operations on values.
    Counter = ::Concurrent::AtomicFixnum

    # Implements space-efficient but statistically useful histogram storage.
    # A precise time histogram stores every time. Instead we break times into a set of
    # known buckets and increment counts of the associated time bucket. Even if we call
    # the histogram a million times, we'll still only store 26 buckets.
    # NB: needs to be thread-safe or resiliant to races.
    #
    # To store this data, we use Redis' BITFIELD command to store unsigned 16-bit counters
    # per bucket per klass per minute. It's unlikely that most people will be executing more
    # than 1000 job/sec for a full minute of a specific type.
    class Histogram
      include Enumerable

      # This number represents the maximum milliseconds for this bucket.
      # 20 means all job executions up to 20ms, e.g. if a job takes
      # 280ms, it'll increment bucket[7]. Note we can track job executions
      # up to about 5.5 minutes. After that, it's assumed you're probably
      # not too concerned with its performance.
      BUCKET_INTERVALS = [
        20, 30, 45, 65, 100,
        150, 225, 335, 500, 750,
        1100, 1700, 2500, 3800, 5750,
        8500, 13000, 20000, 30000, 45000,
        65000, 100000, 150000, 225000, 335000,
        1e20 # the "maybe your job is too long" bucket
      ].freeze
      LABELS = [
        "20ms", "30ms", "45ms", "65ms", "100ms",
        "150ms", "225ms", "335ms", "500ms", "750ms",
        "1.1s", "1.7s", "2.5s", "3.8s", "5.75s",
        "8.5s", "13s", "20s", "30s", "45s",
        "65s", "100s", "150s", "225s", "335s",
        "Slow"
      ].freeze
      FETCH = "GET u16 #0 GET u16 #1 GET u16 #2 GET u16 #3 \
        GET u16 #4 GET u16 #5 GET u16 #6 GET u16 #7 \
        GET u16 #8 GET u16 #9 GET u16 #10 GET u16 #11 \
        GET u16 #12 GET u16 #13 GET u16 #14 GET u16 #15 \
        GET u16 #16 GET u16 #17 GET u16 #18 GET u16 #19 \
        GET u16 #20 GET u16 #21 GET u16 #22 GET u16 #23 \
        GET u16 #24 GET u16 #25".split
      HISTOGRAM_TTL = 8 * 60 * 60

      def each
        buckets.each { |counter| yield counter.value }
      end

      def label(idx)
        LABELS[idx]
      end

      attr_reader :buckets
      def initialize(klass)
        @klass = klass
        @buckets = Array.new(BUCKET_INTERVALS.size) { Counter.new }
      end

      def record_time(ms)
        index_to_use = BUCKET_INTERVALS.each_index do |idx|
          break idx if ms < BUCKET_INTERVALS[idx]
        end

        @buckets[index_to_use].increment
      end

      def fetch(conn, now = Time.now)
        window = now.utc.strftime("%d-%H:%-M")
        key = "#{@klass}-#{window}"
        conn.bitfield_ro(key, *FETCH)
      end

      def persist(conn, now = Time.now)
        buckets, @buckets = @buckets, []
        window = now.utc.strftime("%d-%H:%-M")
        key = "#{@klass}-#{window}"
        cmd = [key, "OVERFLOW", "SAT"]
        buckets.each_with_index do |counter, idx|
          val = counter.value
          cmd << "INCRBY" << "u16" << "##{idx}" << val.to_s if val > 0
        end

        conn.bitfield(*cmd) if cmd.size > 3
        conn.expire(key, HISTOGRAM_TTL)
        key
      end
    end
  end
end
