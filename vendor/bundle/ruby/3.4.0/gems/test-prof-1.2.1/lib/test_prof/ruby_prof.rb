# frozen_string_literal: true

module TestProf
  # RubyProf wrapper.
  #
  # Has 2 modes: global and per-example.
  #
  # Example:
  #
  #   # To activate global profiling you can use env variable
  #   TEST_RUBY_PROF=1 rspec ...
  #
  #   # or in your code
  #   TestProf::RubyProf.run
  #
  # To profile a specific examples add :rprof tag to it:
  #
  #   it "is doing heavy stuff", :rprof do
  #     ...
  #   end
  #
  module RubyProf
    # RubyProf configuration
    class Configuration
      PRINTERS = {
        "flat" => "FlatPrinter",
        "flat_wln" => "FlatPrinterWithLineNumbers",
        "graph" => "GraphPrinter",
        "graph_html" => "GraphHtmlPrinter",
        "dot" => "DotPrinter",
        "." => "DotPrinter",
        "call_stack" => "CallStackPrinter",
        "call_tree" => "CallTreePrinter",
        "multi" => "MultiPrinter"
      }.freeze

      # Mapping from printer to report file extension
      # NOTE: txt is not included and considered default
      PRINTER_EXTENSTION = {
        "graph_html" => "html",
        "dot" => "dot",
        "." => "dot",
        "call_stack" => "html"
      }.freeze

      LOGFILE_PREFIX = "ruby-prof-report"

      attr_accessor :printer, :mode, :min_percent,
        :include_threads, :exclude_common_methods,
        :test_prof_exclusions_enabled,
        :custom_exclusions

      def initialize
        @printer = ENV["TEST_RUBY_PROF"].to_sym if PRINTERS.key?(ENV["TEST_RUBY_PROF"])
        @printer ||= ENV.fetch("TEST_RUBY_PROF_PRINTER", :flat).to_sym
        @mode = ENV.fetch("TEST_RUBY_PROF_MODE", :wall).to_sym
        @min_percent = 1
        @include_threads = false
        @exclude_common_methods = true
        @test_prof_exclusions_enabled = true
        @custom_exclusions = {}
      end

      def include_threads?
        include_threads == true
      end

      def exclude_common_methods?
        exclude_common_methods == true
      end

      def test_prof_exclusions_enabled?
        @test_prof_exclusions_enabled == true
      end

      # Returns an array of printer type (ID) and class.
      def resolve_printer
        return ["custom", printer] if printer.is_a?(Module)

        type = printer.to_s

        raise ArgumentError, "Unknown printer: #{type}" unless
          PRINTERS.key?(type)

        [type, ::RubyProf.const_get(PRINTERS[type])]
      end
    end

    # Wrapper over RubyProf profiler and printer
    class Report
      include TestProf::Logging

      def initialize(profiler)
        @profiler = profiler
      end

      # Stop profiling and generate the report
      # using provided name.
      def dump(name)
        result = @profiler.stop

        printer_type, printer_class = config.resolve_printer

        if %w[call_tree multi].include?(printer_type)
          path = TestProf.create_artifact_dir
          printer_class.new(result).print(
            path: path,
            profile: "#{RubyProf::Configuration::LOGFILE_PREFIX}-#{printer_type}-" \
              "#{config.mode}-#{name}",
            min_percent: config.min_percent
          )
        else
          path = build_path name, printer_type
          File.open(path, "w") do |f|
            printer_class.new(result).print(f, min_percent: config.min_percent)
          end

        end

        log :info, "RubyProf report generated: #{path}"
      end

      private

      def build_path(name, printer)
        TestProf.artifact_path(
          "#{RubyProf::Configuration::LOGFILE_PREFIX}-#{printer}-#{config.mode}-#{name}" \
          ".#{RubyProf::Configuration::PRINTER_EXTENSTION.fetch(printer, "txt")}"
        )
      end

      def config
        RubyProf.config
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

      # Run RubyProf and automatically dump
      # a report when the process exits.
      #
      # Use this method to profile the whole run.
      def run
        report = profile

        return unless report

        @locked = true

        log :info, "RubyProf enabled globally"

        at_exit { report.dump("total") }
      end

      def profile
        if locked?
          log :warn, <<~MSG
            RubyProf is activated globally, you cannot generate per-example report.

            Make sure you haven's set the TEST_RUBY_PROF environmental variable.
          MSG
          return
        end

        return unless init_ruby_prof

        options = {}

        options[:include_threads] = [Thread.current] unless
          config.include_threads?

        profiler = ::RubyProf::Profile.new(options)
        profiler.exclude_common_methods! if config.exclude_common_methods?

        if config.test_prof_exclusions_enabled?
          # custom test-prof exclusions
          exclude_rspec_methods(profiler)

          # custom global exclusions
          exclude_common_methods(profiler)
        end

        config.custom_exclusions.each do |klass, mids|
          profiler.exclude_methods! klass, *mids
        end

        profiler.start

        Report.new(profiler)
      end

      private

      def locked?
        @locked == true
      end

      def init_ruby_prof
        return @initialized if instance_variable_defined?(:@initialized)
        ENV["RUBY_PROF_MEASURE_MODE"] = config.mode.to_s
        @initialized = TestProf.require(
          "ruby-prof",
          <<~MSG
            Please, install 'ruby-prof' first:
               # Gemfile
              gem 'ruby-prof', '>= 1.4.0', require: false
          MSG
        ) { check_ruby_prof_version }
      end

      def check_ruby_prof_version
        if Utils.verify_gem_version("ruby-prof", at_least: "0.17.0")
          true
        else
          log :error, <<~MGS
            Please, upgrade 'ruby-prof' to version >= 0.17.0.
          MGS
          false
        end
      end

      def exclude_rspec_methods(profiler)
        return unless TestProf.rspec?

        RSpecExclusions.generate.each do |klass, mids|
          profiler.exclude_methods!(klass, *mids)
        end
      end

      def exclude_common_methods(profiler)
        if defined?(TSort)
          profiler.exclude_methods!(
            TSort,
            :tsort_each
          )

          profiler.exclude_methods!(
            TSort.singleton_class,
            :tsort_each, :each_strongly_connected_component,
            :each_strongly_connected_component_from
          )
        end

        profiler.exclude_methods!(
          BasicObject,
          :instance_exec
        )
      end
    end
  end
end

if TestProf.rspec?
  require "test_prof/ruby_prof/rspec"
  require "test_prof/ruby_prof/rspec_exclusions"
end

# Hook to run RubyProf globally
TestProf.activate("TEST_RUBY_PROF") do
  TestProf::RubyProf.run
end
