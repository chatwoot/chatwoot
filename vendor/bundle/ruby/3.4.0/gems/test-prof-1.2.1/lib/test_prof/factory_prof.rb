# frozen_string_literal: true

require "test_prof/factory_prof/printers/simple"
require "test_prof/factory_prof/printers/flamegraph"
require "test_prof/factory_prof/printers/nate_heckler"
require "test_prof/factory_prof/factory_builders/factory_bot"
require "test_prof/factory_prof/factory_builders/fabrication"

module TestProf
  # FactoryProf collects "factory stacks" that can be used to build
  # flamegraphs or detect most popular factories
  module FactoryProf
    FACTORY_BUILDERS = [FactoryBuilders::FactoryBot,
      FactoryBuilders::Fabrication].freeze

    # FactoryProf configuration
    class Configuration
      attr_accessor :mode, :printer

      def initialize
        @mode = (ENV["FPROF"] == "flamegraph") ? :flamegraph : :simple
        @printer =
          case ENV["FPROF"]
          when "flamegraph"
            Printers::Flamegraph
          when "nate_heckler"
            Printers::NateHeckler
          else
            Printers::Simple
          end
      end

      # Whether we want to generate flamegraphs
      def flamegraph?
        @mode == :flamegraph
      end
    end

    class Result # :nodoc:
      attr_reader :stacks, :raw_stats

      def initialize(stacks, raw_stats)
        @stacks = stacks
        @raw_stats = raw_stats
      end

      # Returns sorted stats
      def stats
        @stats ||= @raw_stats.values
          .sort_by { |el| -el[:total_count] }
      end

      def total_count
        @total_count ||= @raw_stats.values.sum { |v| v[:total_count] }
      end

      def total_time
        @total_time ||= @raw_stats.values.sum { |v| v[:total_time] }
      end

      private

      def sorted_stats(key)
        @raw_stats.values
          .map { |el| [el[:name], el[key]] }
          .sort_by { |el| -el[1] }
      end
    end

    class << self
      include TestProf::Logging

      def config
        @config ||= Configuration.new
      end

      def configure
        yield config
      end

      # Patch factory lib, init vars
      def init
        @running = false

        log :info, "FactoryProf enabled (#{config.mode} mode)"

        patch!
      end

      def patch!
        return if @patched

        FACTORY_BUILDERS.each(&:patch)

        @patched = true
      end

      # Inits FactoryProf and setups at exit hook,
      # then runs
      def run
        init

        started_at = TestProf.now

        at_exit do
          print(started_at)
        end

        start
      end

      def print(started_at)
        printer = config.printer

        printer.dump(result, start_time: started_at)
      end

      def start
        reset!
        @running = true
      end

      def stop
        @running = false
      end

      def result
        Result.new(@stacks, @stats)
      end

      def track(factory)
        return yield unless running?
        @depth += 1
        @current_stack << factory if config.flamegraph?
        @stats[factory][:total_count] += 1
        @stats[factory][:top_level_count] += 1 if @depth == 1
        t1 = TestProf.now
        begin
          yield
        ensure
          t2 = TestProf.now
          elapsed = t2 - t1
          @stats[factory][:total_time] += elapsed
          @stats[factory][:top_level_time] += elapsed if @depth == 1
          @depth -= 1
          flush_stack if @depth.zero?
        end
      end

      private

      def reset!
        @stacks = [] if config.flamegraph?
        @depth = 0
        @stats = Hash.new do |h, k|
          h[k] = {
            name: k,
            total_count: 0,
            top_level_count: 0,
            total_time: 0.0,
            top_level_time: 0.0
          }
        end
        flush_stack
      end

      def flush_stack
        return unless config.flamegraph?
        @stacks << @current_stack unless @current_stack.nil? || @current_stack.empty?
        @current_stack = []
      end

      def running?
        @running == true
      end
    end
  end
end

TestProf.activate("FPROF") do
  TestProf::FactoryProf.run
end
