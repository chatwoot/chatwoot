# frozen_string_literal: true

require "test_prof/rspec_stamp"
require "test_prof/logging"

module TestProf
  # RSpecDissect tracks how much time do you spend in `before` hooks
  # and memoization helpers (i.e. `let`) in your tests.
  module RSpecDissect
    module ExampleInstrumentation # :nodoc:
      def run_before_example(*)
        RSpecDissect.track(:before) { super }
      end
    end

    module MemoizedInstrumentation # :nodoc:
      def fetch_or_store(id, *)
        res = nil
        Thread.current[:_rspec_dissect_let_depth] ||= 0
        Thread.current[:_rspec_dissect_let_depth] += 1
        begin
          res = if Thread.current[:_rspec_dissect_let_depth] == 1
            RSpecDissect.track(:let, id) { super }
          else
            super
          end
        ensure
          Thread.current[:_rspec_dissect_let_depth] -= 1
        end
        res
      end
    end

    # RSpecDisect configuration
    class Configuration
      MODES = %w[all let before].freeze

      attr_accessor :top_count, :let_stats_enabled,
        :let_top_count

      alias_method :let_stats_enabled?, :let_stats_enabled

      attr_reader :mode

      def initialize
        @let_stats_enabled = true
        @let_top_count = (ENV["RD_PROF_LET_TOP"] || 3).to_i
        @top_count = (ENV["RD_PROF_TOP"] || 5).to_i
        @stamp = ENV["RD_PROF_STAMP"]
        @mode = (ENV["RD_PROF"] == "1") ? "all" : ENV["RD_PROF"]

        unless MODES.include?(mode)
          raise "Unknown RSpecDissect mode: #{mode};" \
                "available modes: #{MODES.join(", ")}"
        end

        RSpecStamp.config.tags = @stamp if stamp?
      end

      def let?
        mode == "all" || mode == "let"
      end

      def before?
        mode == "all" || mode == "before"
      end

      def stamp?
        !@stamp.nil?
      end
    end

    METRICS = %w[before let].freeze

    class << self
      include Logging

      def config
        @config ||= Configuration.new
      end

      def configure
        yield config
      end

      def init
        RSpec::Core::Example.prepend(ExampleInstrumentation)

        RSpec::Core::MemoizedHelpers::ThreadsafeMemoized.prepend(MemoizedInstrumentation)
        RSpec::Core::MemoizedHelpers::NonThreadSafeMemoized.prepend(MemoizedInstrumentation)

        @data = {}

        METRICS.each do |type|
          @data["total_#{type}"] = 0.0
        end

        reset!

        log :info, "RSpecDissect enabled"
      end

      def track(type, meta = nil)
        start = TestProf.now
        res = yield
        delta = (TestProf.now - start)
        type = type.to_s
        @data[type][:time] += delta
        @data[type][:meta] << meta unless meta.nil?
        @data["total_#{type}"] += delta
        res
      end

      def reset!
        METRICS.each do |type|
          @data[type.to_s] = {time: 0.0, meta: []}
        end
      end

      # Whether we are able to track `let` usage
      def memoization_available?
        defined?(::RSpec::Core::MemoizedHelpers::ThreadsafeMemoized)
      end

      def time_for(key)
        @data[key.to_s][:time]
      end

      def meta_for(key)
        @data[key.to_s][:meta]
      end

      def total_time_for(key)
        @data["total_#{key}"]
      end
    end
  end
end

require "test_prof/rspec_dissect/collectors/let"
require "test_prof/rspec_dissect/collectors/before"
require "test_prof/rspec_dissect/rspec"

TestProf.activate("RD_PROF") do
  TestProf::RSpecDissect.init
end
