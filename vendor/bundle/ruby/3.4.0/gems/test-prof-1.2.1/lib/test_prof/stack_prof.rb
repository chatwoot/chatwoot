# frozen_string_literal: true

module TestProf
  # StackProf wrapper.
  #
  # Has 2 modes: global and per-example.
  #
  # Example:
  #
  #   # To activate global profiling you can use env variable
  #   TEST_STACK_PROF=1 rspec ...
  #
  #   # or in your code
  #   TestProf::StackProf.run
  #
  # To profile a specific examples add :sprof tag to it:
  #
  #   it "is doing heavy stuff", :sprof do
  #     ...
  #   end
  #
  module StackProf
    # StackProf configuration
    class Configuration
      FORMATS = %w[html json].freeze

      attr_accessor :mode, :raw, :target, :format, :interval, :ignore_gc
      def initialize
        @mode = ENV.fetch("TEST_STACK_PROF_MODE", :wall).to_sym
        @target = (ENV["TEST_STACK_PROF"] == "boot") ? :boot : :suite
        @raw = ENV["TEST_STACK_PROF_RAW"] != "0"
        @format =
          if FORMATS.include?(ENV["TEST_STACK_PROF_FORMAT"])
            ENV["TEST_STACK_PROF_FORMAT"]
          else
            "html"
          end

        sample_interval = ENV["TEST_STACK_PROF_INTERVAL"].to_i
        @interval = (sample_interval > 0) ? sample_interval : nil
        @ignore_gc = !ENV["TEST_STACK_PROF_IGNORE_GC"].nil?
      end

      def raw?
        @raw == true
      end

      def boot?
        target == :boot
      end

      def suite?
        target == :suite
      end
    end

    class << self
      include Logging

      def config
        @config ||= Configuration.new
      end

      def configure
        yield config
      end

      # Run StackProf and automatically dump
      # a report when the process exits or when the application is booted.
      def run
        return unless profile

        @locked = true

        log :info, "StackProf#{config.raw? ? " (raw)" : ""} enabled globally: " \
                   "mode – #{config.mode}, target – #{config.target}"

        at_exit { dump("total") } if config.suite?
      end

      def profile(name = nil)
        if locked?
          log :warn, <<~MSG
            StackProf is activated globally, you cannot generate per-example report.

            Make sure you haven's set the TEST_STACK_PROF environmental variable.
          MSG
          return false
        end

        return false unless init_stack_prof

        options = {
          mode: config.mode,
          raw: config.raw
        }

        options[:interval] = config.interval if config.interval
        options[:ignore_gc] = true if config.ignore_gc

        if block_given?
          options[:out] = build_path(name)
          ::StackProf.run(**options) { yield }
        else
          ::StackProf.start(**options)
        end
        true
      end

      def dump(name)
        ::StackProf.stop

        path = build_path(name)

        ::StackProf.results(path)

        log :info, "StackProf report generated: #{path}"

        return unless config.raw

        send("dump_#{config.format}_report", path)
      end

      private

      def build_path(name)
        TestProf.artifact_path(
          "stack-prof-report-#{config.mode}#{config.raw ? "-raw" : ""}-#{name}.dump"
        )
      end

      def locked?
        @locked == true
      end

      def init_stack_prof
        return @initialized if instance_variable_defined?(:@initialized)
        @locked = false
        @initialized = TestProf.require(
          "stackprof",
          <<~MSG
            Please, install 'stackprof' first:
               # Gemfile
              gem 'stackprof', '>= 0.2.9', require: false
          MSG
        ) { check_stack_prof_version }
      end

      def check_stack_prof_version
        if Utils.verify_gem_version("stackprof", at_least: "0.2.9")
          true
        else
          log :error, <<~MSG
            Please, upgrade 'stackprof' to version >= 0.2.9.
          MSG
          false
        end
      end

      def dump_html_report(path)
        html_path = path.gsub(/\.dump$/, ".html")

        log :info, <<~MSG
          Run the following command to generate a flame graph report:

          stackprof --d3-flamegraph #{path} > #{html_path} && stackprof --flamegraph-viewer=#{html_path}
        MSG
      end

      def dump_json_report(path)
        report = ::StackProf::Report.new(
          Marshal.load(IO.binread(path))
        )
        json_path = path.gsub(/\.dump$/, ".json")
        File.write(json_path, JSON.generate(report.data))

        log :info, <<~MSG
          StackProf JSON report generated: #{json_path}
        MSG
      end
    end
  end
end

require "test_prof/stack_prof/rspec" if TestProf.rspec?

# Hook to run StackProf globally
TestProf.activate("TEST_STACK_PROF") do
  TestProf::StackProf.run
end
