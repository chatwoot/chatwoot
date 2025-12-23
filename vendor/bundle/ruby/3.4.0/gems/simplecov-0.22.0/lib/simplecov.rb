# frozen_string_literal: true

require "English"

# Coverage may be inaccurate under JRUBY.
if defined?(JRUBY_VERSION) && defined?(JRuby) && !org.jruby.RubyInstanceConfig.FULL_TRACE_ENABLED

  # @see https://github.com/jruby/jruby/issues/1196
  # @see https://github.com/metricfu/metric_fu/pull/226
  # @see https://github.com/simplecov-ruby/simplecov/issues/420
  # @see https://github.com/simplecov-ruby/simplecov/issues/86
  # @see https://jira.codehaus.org/browse/JRUBY-6106

  warn 'Coverage may be inaccurate; set the "--debug" command line option,' \
    ' or do JRUBY_OPTS="--debug"' \
    ' or set the "debug.fullTrace=true" option in your .jrubyrc'
end

#
# Code coverage for ruby. Please check out README for a full introduction.
#
module SimpleCov
  class << self
    attr_accessor :running, :pid

    # Basically, should we take care of at_exit behavior or something else?
    # Used by the minitest plugin. See lib/minitest/simplecov_plugin.rb
    attr_accessor :external_at_exit
    alias external_at_exit? external_at_exit

    #
    # Sets up SimpleCov to run against your project.
    # You can optionally specify a profile to use as well as configuration with a block:
    #   SimpleCov.start
    #    OR
    #   SimpleCov.start 'rails' # using rails profile
    #    OR
    #   SimpleCov.start do
    #     add_filter 'test'
    #   end
    #     OR
    #   SimpleCov.start 'rails' do
    #     add_filter 'test'
    #   end
    #
    # Please check out the RDoc for SimpleCov::Configuration to find about available config options
    #
    def start(profile = nil, &block)
      require "coverage"
      initial_setup(profile, &block)
      require_relative "./simplecov/process" if SimpleCov.enabled_for_subprocesses? &&
                                                ::Process.respond_to?(:fork)

      make_parallel_tests_available

      @result = nil
      self.pid = Process.pid

      start_coverage_measurement
    end

    #
    # Collate a series of SimpleCov result files into a single SimpleCov output.
    #
    # You can optionally specify configuration with a block:
    #   SimpleCov.collate Dir["simplecov-resultset-*/.resultset.json"]
    #    OR
    #   SimpleCov.collate Dir["simplecov-resultset-*/.resultset.json"], 'rails' # using rails profile
    #    OR
    #   SimpleCov.collate Dir["simplecov-resultset-*/.resultset.json"] do
    #     add_filter 'test'
    #   end
    #    OR
    #   SimpleCov.collate Dir["simplecov-resultset-*/.resultset.json"], 'rails' do
    #     add_filter 'test'
    #   end
    #
    # Please check out the RDoc for SimpleCov::Configuration to find about
    # available config options, or checkout the README for more in-depth
    # information about coverage collation
    #
    # By default `collate` ignores the merge_timeout so all results of all files specified will be
    # merged together. If you want to honor the merge_timeout then provide the keyword argument
    # `ignore_timeout: false`.
    #
    def collate(result_filenames, profile = nil, ignore_timeout: true, &block)
      raise "There are no reports to be merged" if result_filenames.empty?

      initial_setup(profile, &block)

      # Use the ResultMerger to produce a single, merged result, ready to use.
      @result = ResultMerger.merge_and_store(*result_filenames, ignore_timeout: ignore_timeout)

      run_exit_tasks!
    end

    #
    # Returns the result for the current coverage run, merging it across test suites
    # from cache using SimpleCov::ResultMerger if use_merging is activated (default)
    #
    def result
      return @result if result?

      # Collect our coverage result
      process_coverage_result if running

      # If we're using merging of results, store the current result
      # first (if there is one), then merge the results and return those
      if use_merging
        wait_for_other_processes
        SimpleCov::ResultMerger.store_result(@result) if result?
        @result = SimpleCov::ResultMerger.merged_result
      end

      @result
    ensure
      self.running = false
    end

    #
    # Returns nil if the result has not been computed
    # Otherwise, returns the result
    #
    def result?
      defined?(@result) && @result
    end

    #
    # Applies the configured filters to the given array of SimpleCov::SourceFile items
    #
    def filtered(files)
      result = files.clone
      filters.each do |filter|
        result = result.reject { |source_file| filter.matches?(source_file) }
      end
      SimpleCov::FileList.new result
    end

    #
    # Applies the configured groups to the given array of SimpleCov::SourceFile items
    #
    def grouped(files)
      grouped = {}
      grouped_files = []
      groups.each do |name, filter|
        grouped[name] = SimpleCov::FileList.new(files.select { |source_file| filter.matches?(source_file) })
        grouped_files += grouped[name]
      end
      if !groups.empty? && !(other_files = files.reject { |source_file| grouped_files.include?(source_file) }).empty?
        grouped["Ungrouped"] = SimpleCov::FileList.new(other_files)
      end
      grouped
    end

    #
    # Applies the profile of given name on SimpleCov configuration
    #
    def load_profile(name)
      profiles.load(name)
    end

    def load_adapter(name)
      warn "#{Kernel.caller.first}: [DEPRECATION] #load_adapter is deprecated. Use #load_profile instead."
      load_profile(name)
    end

    #
    # Clear out the previously cached .result. Primarily useful in testing
    #
    def clear_result
      @result = nil
    end

    def at_exit_behavior
      # If we are in a different process than called start, don't interfere.
      return if SimpleCov.pid != Process.pid

      # If SimpleCov is no longer running then don't run exit tasks
      SimpleCov.run_exit_tasks! if SimpleCov.running
    end

    # @api private
    #
    # Called from at_exit block
    #
    def run_exit_tasks!
      error_exit_status = exit_status_from_exception

      at_exit.call

      exit_and_report_previous_error(error_exit_status) if previous_error?(error_exit_status)
      process_results_and_report_error if ready_to_process_results?
    end

    #
    # @api private
    #
    # Returns the exit status from the exit exception
    #
    def exit_status_from_exception
      # Capture the current exception if it exists
      @exit_exception = $ERROR_INFO
      return nil unless @exit_exception

      if @exit_exception.is_a?(SystemExit)
        @exit_exception.status
      else
        SimpleCov::ExitCodes::EXCEPTION
      end
    end

    # @api private
    def previous_error?(error_exit_status)
      # Normally it'd be enough to check for previous error but when running test_unit
      # status is 0
      error_exit_status && error_exit_status != SimpleCov::ExitCodes::SUCCESS
    end

    #
    # @api private
    #
    # Thinking: Move this behavior earlier so if there was an error we do nothing?
    def exit_and_report_previous_error(exit_status)
      warn("Stopped processing SimpleCov as a previous error not related to SimpleCov has been detected") if print_error_status
      Kernel.exit(exit_status)
    end

    # @api private
    def ready_to_process_results?
      final_result_process? && result?
    end

    def process_results_and_report_error
      exit_status = process_result(result)

      # Force exit with stored status (see github issue #5)
      if exit_status.positive?
        warn("SimpleCov failed with exit #{exit_status} due to a coverage related error") if print_error_status
        Kernel.exit exit_status
      end
    end

    # @api private
    #
    # Usage:
    #   exit_status = SimpleCov.process_result(SimpleCov.result, exit_status)
    #
    def process_result(result)
      result_exit_status = result_exit_status(result)
      write_last_run(result) if result_exit_status == SimpleCov::ExitCodes::SUCCESS
      result_exit_status
    end

    # @api private
    CoverageLimits = Struct.new(:minimum_coverage, :minimum_coverage_by_file, :maximum_coverage_drop, keyword_init: true)
    def result_exit_status(result)
      coverage_limits = CoverageLimits.new(
        minimum_coverage: minimum_coverage, minimum_coverage_by_file: minimum_coverage_by_file,
        maximum_coverage_drop: maximum_coverage_drop
      )

      ExitCodes::ExitCodeHandling.call(result, coverage_limits: coverage_limits)
    end

    #
    # @api private
    #
    def final_result_process?
      # checking for ENV["TEST_ENV_NUMBER"] to determine if the tests are being run in parallel
      !defined?(ParallelTests) || !ENV["TEST_ENV_NUMBER"] || ParallelTests.last_process?
    end

    #
    # @api private
    #
    def wait_for_other_processes
      return unless defined?(ParallelTests) && final_result_process?

      ParallelTests.wait_for_other_processes_to_finish
    end

    #
    # @api private
    #
    def write_last_run(result)
      SimpleCov::LastRun.write(result:
        result.coverage_statistics.transform_values do |stats|
          round_coverage(stats.percent)
        end)
    end

    #
    # @api private
    #
    # Rounding down to be extra strict, see #679
    def round_coverage(coverage)
      coverage.floor(2)
    end

  private

    def initial_setup(profile, &block)
      load_profile(profile) if profile
      configure(&block) if block_given?
      self.running = true
    end

    #
    # Trigger Coverage.start depends on given config coverage_criterion
    #
    # With Positive branch it supports all coverage measurement types
    # With Negative branch it supports only line coverage measurement type
    #
    def start_coverage_measurement
      # This blog post gives a good run down of the coverage criterias introduced
      # in Ruby 2.5: https://blog.bigbinary.com/2018/04/11/ruby-2-5-supports-measuring-branch-and-method-coverages.html
      # There is also a nice writeup of the different coverage criteria made in this
      # comment  https://github.com/simplecov-ruby/simplecov/pull/692#discussion_r281836176 :
      # Ruby < 2.5:
      # https://github.com/ruby/ruby/blob/v1_9_3_374/ext/coverage/coverage.c
      # traditional mode (Array)
      #
      # Ruby 2.5:
      # https://bugs.ruby-lang.org/issues/13901
      # https://github.com/ruby/ruby/blob/v2_5_3/ext/coverage/coverage.c
      # default: traditional/compatible mode (Array)
      # :lines - like traditional mode but using Hash
      # :branches
      # :methods
      # :all - same as lines + branches + methods
      #
      # Ruby >= 2.6:
      # https://bugs.ruby-lang.org/issues/15022
      # https://github.com/ruby/ruby/blob/v2_6_3/ext/coverage/coverage.c
      # default: traditional/compatible mode (Array)
      # :lines - like traditional mode but using Hash
      # :branches
      # :methods
      # :oneshot_lines - can not be combined with lines
      # :all - same as lines + branches + methods
      #
      if coverage_start_arguments_supported?
        start_coverage_with_criteria
      else
        Coverage.start unless Coverage.running?
      end
    end

    def start_coverage_with_criteria
      start_arguments = coverage_criteria.map do |criterion|
        [lookup_corresponding_ruby_coverage_name(criterion), true]
      end.to_h

      start_arguments[:eval] = true if coverage_for_eval_enabled?

      Coverage.start(start_arguments) unless Coverage.running?
    end

    CRITERION_TO_RUBY_COVERAGE = {
      branch: :branches,
      line: :lines
    }.freeze
    def lookup_corresponding_ruby_coverage_name(criterion)
      CRITERION_TO_RUBY_COVERAGE.fetch(criterion)
    end

    #
    # Finds files that were to be tracked but were not loaded and initializes
    # the line-by-line coverage to zero (if relevant) or nil (comments / whitespace etc).
    #
    def add_not_loaded_files(result)
      if tracked_files
        result = result.dup
        Dir[tracked_files].each do |file|
          absolute_path = File.expand_path(file)
          result[absolute_path] ||= SimulateCoverage.call(absolute_path)
        end
      end

      result
    end

    #
    # Call steps that handle process coverage result
    #
    # @return [Hash]
    #
    def process_coverage_result
      adapt_coverage_result
      remove_useless_results
      result_with_not_loaded_files
    end

    #
    # Unite the result so it wouldn't matter what coverage type was called
    #
    # @return [Hash]
    #
    def adapt_coverage_result
      @result = SimpleCov::ResultAdapter.call(Coverage.result)
    end

    #
    # Filter coverage result
    # The result before filter also has result of coverage for files
    # are not related to the project like loaded gems coverage.
    #
    # @return [Hash]
    #
    def remove_useless_results
      @result = SimpleCov::UselessResultsRemover.call(@result)
    end

    #
    # Initialize result with files that are not included by coverage
    # and added inside the config block
    #
    # @return [Hash]
    #
    def result_with_not_loaded_files
      @result = SimpleCov::Result.new(add_not_loaded_files(@result))
    end

    # parallel_tests isn't always available, see: https://github.com/grosser/parallel_tests/issues/772
    def make_parallel_tests_available
      return if defined?(ParallelTests)
      return unless probably_running_parallel_tests?

      require "parallel_tests"
    rescue LoadError
      warn("SimpleCov guessed you were running inside parallel tests but couldn't load it. Please file a bug report with us!")
    end

    def probably_running_parallel_tests?
      ENV["TEST_ENV_NUMBER"] && ENV["PARALLEL_TEST_GROUPS"]
    end
  end
end

# requires are down here here for a load order reason I'm not sure what it is about
require "set"
require "forwardable"
require_relative "simplecov/configuration"
SimpleCov.extend SimpleCov::Configuration
require_relative "simplecov/coverage_statistics"
require_relative "simplecov/exit_codes"
require_relative "simplecov/profiles"
require_relative "simplecov/source_file/line"
require_relative "simplecov/source_file/branch"
require_relative "simplecov/source_file"
require_relative "simplecov/file_list"
require_relative "simplecov/result"
require_relative "simplecov/filter"
require_relative "simplecov/formatter"
require_relative "simplecov/last_run"
require_relative "simplecov/lines_classifier"
require_relative "simplecov/result_merger"
require_relative "simplecov/command_guesser"
require_relative "simplecov/version"
require_relative "simplecov/result_adapter"
require_relative "simplecov/combine"
require_relative "simplecov/combine/branches_combiner"
require_relative "simplecov/combine/files_combiner"
require_relative "simplecov/combine/lines_combiner"
require_relative "simplecov/combine/results_combiner"
require_relative "simplecov/useless_results_remover"
require_relative "simplecov/simulate_coverage"

# Load default config
require_relative "simplecov/defaults" unless ENV["SIMPLECOV_NO_DEFAULTS"]
