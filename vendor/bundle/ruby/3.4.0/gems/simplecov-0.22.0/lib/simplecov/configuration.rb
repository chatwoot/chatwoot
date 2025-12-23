# frozen_string_literal: true

require "fileutils"
require "docile"
require_relative "formatter/multi_formatter"

module SimpleCov
  #
  # Bundles the configuration options used for SimpleCov. All methods
  # defined here are usable from SimpleCov directly. Please check out
  # SimpleCov documentation for further info.
  #
  module Configuration
    attr_writer :filters, :groups, :formatter, :print_error_status

    #
    # The root for the project. This defaults to the
    # current working directory.
    #
    # Configure with SimpleCov.root('/my/project/path')
    #
    def root(root = nil)
      return @root if defined?(@root) && root.nil?

      @coverage_path = nil # invalidate cache
      @root = File.expand_path(root || Dir.getwd)
    end

    #
    # The name of the output and cache directory. Defaults to 'coverage'
    #
    # Configure with SimpleCov.coverage_dir('cov')
    #
    def coverage_dir(dir = nil)
      return @coverage_dir if defined?(@coverage_dir) && dir.nil?

      @coverage_path = nil # invalidate cache
      @coverage_dir = (dir || "coverage")
    end

    #
    # Returns the full path to the output directory using SimpleCov.root
    # and SimpleCov.coverage_dir, so you can adjust this by configuring those
    # values. Will create the directory if it's missing
    #
    def coverage_path
      @coverage_path ||= begin
        coverage_path = File.expand_path(coverage_dir, root)
        FileUtils.mkdir_p coverage_path
        coverage_path
      end
    end

    #
    # Coverage results will always include files matched by this glob, whether
    # or not they were explicitly required. Without this, un-required files
    # will not be present in the final report.
    #
    def track_files(glob)
      @tracked_files = glob
    end

    #
    # Returns the glob that will be used to include files that were not
    # explicitly required.
    #
    def tracked_files
      @tracked_files if defined?(@tracked_files)
    end

    #
    # Returns the list of configured filters. Add filters using SimpleCov.add_filter.
    #
    def filters
      @filters ||= []
    end

    # The name of the command (a.k.a. Test Suite) currently running. Used for result
    # merging and caching. It first tries to make a guess based upon the command line
    # arguments the current test suite is running on and should automatically detect
    # unit tests, functional tests, integration tests, rpsec and cucumber and label
    # them properly. If it fails to recognize the current command, the command name
    # is set to the shell command that the current suite is running on.
    #
    # You can specify it manually with SimpleCov.command_name("test:units") - please
    # also check out the corresponding section in README.rdoc
    def command_name(name = nil)
      @name = name unless name.nil?
      @name ||= SimpleCov::CommandGuesser.guess
      @name
    end

    #
    # Gets or sets the configured formatter.
    #
    # Configure with: SimpleCov.formatter(SimpleCov::Formatter::SimpleFormatter)
    #
    def formatter(formatter = nil)
      return @formatter if defined?(@formatter) && formatter.nil?

      @formatter = formatter
      raise "No formatter configured. Please specify a formatter using SimpleCov.formatter = SimpleCov::Formatter::SimpleFormatter" unless @formatter

      @formatter
    end

    #
    # Sets the configured formatters.
    #
    def formatters=(formatters)
      @formatter = SimpleCov::Formatter::MultiFormatter.new(formatters)
    end

    #
    # Gets the configured formatters.
    #
    def formatters
      if @formatter.is_a?(SimpleCov::Formatter::MultiFormatter)
        @formatter.formatters
      else
        Array(formatter)
      end
    end

    #
    # Whether we should print non-success status codes. This can be
    # configured with the #print_error_status= method.
    #
    def print_error_status
      defined?(@print_error_status) ? @print_error_status : true
    end

    #
    # Certain code blocks (i.e. Ruby-implementation specific code) can be excluded from
    # the coverage metrics by wrapping it inside # :nocov: comment blocks. The nocov token
    # can be configured to be any other string using this.
    #
    # Configure with SimpleCov.nocov_token('skip') or it's alias SimpleCov.skip_token('skip')
    #
    def nocov_token(nocov_token = nil)
      return @nocov_token if defined?(@nocov_token) && nocov_token.nil?

      @nocov_token = (nocov_token || "nocov")
    end
    alias skip_token nocov_token

    #
    # Returns the configured groups. Add groups using SimpleCov.add_group
    #
    def groups
      @groups ||= {}
    end

    #
    # Returns the hash of available profiles
    #
    def profiles
      @profiles ||= SimpleCov::Profiles.new
    end

    def adapters
      warn "#{Kernel.caller.first}: [DEPRECATION] #adapters is deprecated. Use #profiles instead."
      profiles
    end

    #
    # Allows you to configure simplecov in a block instead of prepending SimpleCov to all config methods
    # you're calling.
    #
    #     SimpleCov.configure do
    #       add_filter 'foobar'
    #     end
    #
    # This is equivalent to SimpleCov.add_filter 'foobar' and thus makes it easier to set a bunch of configure
    # options at once.
    #
    def configure(&block)
      Docile.dsl_eval(self, &block)
    end

    #
    # Gets or sets the behavior to process coverage results.
    #
    # By default, it will call SimpleCov.result.format!
    #
    # Configure with:
    #
    #     SimpleCov.at_exit do
    #       puts "Coverage done"
    #       SimpleCov.result.format!
    #     end
    #
    def at_exit(&block)
      return Proc.new unless running || block_given?

      @at_exit = block if block_given?
      @at_exit ||= proc { SimpleCov.result.format! }
    end

    # gets or sets the enabled_for_subprocess configuration
    # when true, this will inject SimpleCov code into Process.fork
    def enable_for_subprocesses(value = nil)
      return @enable_for_subprocesses if defined?(@enable_for_subprocesses) && value.nil?

      @enable_for_subprocesses = value || false
    end

    # gets the enabled_for_subprocess configuration
    def enabled_for_subprocesses?
      enable_for_subprocesses
    end

    #
    # Gets or sets the behavior to start a new forked Process.
    #
    # By default, it will add " (Process #{pid})" to the command_name, and start SimpleCov in quiet mode
    #
    # Configure with:
    #
    #     SimpleCov.at_fork do |pid|
    #       SimpleCov.start do
    #         # This needs a unique name so it won't be ovewritten
    #         SimpleCov.command_name "#{SimpleCov.command_name} (subprocess: #{pid})"
    #         # be quiet, the parent process will be in charge of using the regular formatter and checking coverage totals
    #         SimpleCov.print_error_status = false
    #         SimpleCov.formatter SimpleCov::Formatter::SimpleFormatter
    #         SimpleCov.minimum_coverage 0
    #         # start
    #         SimpleCov.start
    #       end
    #     end
    #
    def at_fork(&block)
      @at_fork = block if block_given?
      @at_fork ||= lambda { |pid|
        # This needs a unique name so it won't be ovewritten
        SimpleCov.command_name "#{SimpleCov.command_name} (subprocess: #{pid})"
        # be quiet, the parent process will be in charge of using the regular formatter and checking coverage totals
        SimpleCov.print_error_status = false
        SimpleCov.formatter SimpleCov::Formatter::SimpleFormatter
        SimpleCov.minimum_coverage 0
        # start
        SimpleCov.start
      }
    end

    #
    # Returns the project name - currently assuming the last dirname in
    # the SimpleCov.root is this.
    #
    def project_name(new_name = nil)
      return @project_name if defined?(@project_name) && @project_name && new_name.nil?

      @project_name = new_name if new_name.is_a?(String)
      @project_name ||= File.basename(root.split("/").last).capitalize.tr("_", " ")
    end

    #
    # Defines whether to use result merging so all your test suites (test:units, test:functionals, cucumber, ...)
    # are joined and combined into a single coverage report
    #
    def use_merging(use = nil)
      @use_merging = use unless use.nil?
      @use_merging = true unless defined?(@use_merging) && @use_merging == false
    end

    #
    # Defines the maximum age (in seconds) of a resultset to still be included in merged results.
    # i.e. If you run cucumber features, then later rake test, if the stored cucumber resultset is
    # more seconds ago than specified here, it won't be taken into account when merging (and is also
    # purged from the resultset cache)
    #
    # Of course, this only applies when merging is active (e.g. SimpleCov.use_merging is not false!)
    #
    # Default is 600 seconds (10 minutes)
    #
    # Configure with SimpleCov.merge_timeout(3600) # 1hr
    #
    def merge_timeout(seconds = nil)
      @merge_timeout = seconds if seconds.is_a?(Integer)
      @merge_timeout ||= 600
    end

    #
    # Defines the minimum overall coverage required for the testsuite to pass.
    # SimpleCov will return non-zero if the current coverage is below this threshold.
    #
    # Default is 0% (disabled)
    #
    def minimum_coverage(coverage = nil)
      return @minimum_coverage ||= {} unless coverage

      coverage = {primary_coverage => coverage} if coverage.is_a?(Numeric)

      raise_on_invalid_coverage(coverage, "minimum_coverage")

      @minimum_coverage = coverage
    end

    def raise_on_invalid_coverage(coverage, coverage_setting)
      coverage.each_key { |criterion| raise_if_criterion_disabled(criterion) }
      coverage.each_value do |percent|
        minimum_possible_coverage_exceeded(coverage_setting) if percent && percent > 100
      end
    end

    #
    # Defines the maximum coverage drop at once allowed for the testsuite to pass.
    # SimpleCov will return non-zero if the coverage decreases by more than this threshold.
    #
    # Default is 100% (disabled)
    #
    def maximum_coverage_drop(coverage_drop = nil)
      return @maximum_coverage_drop ||= {} unless coverage_drop

      coverage_drop = {primary_coverage => coverage_drop} if coverage_drop.is_a?(Numeric)

      raise_on_invalid_coverage(coverage_drop, "maximum_coverage_drop")

      @maximum_coverage_drop = coverage_drop
    end

    #
    # Defines the minimum coverage per file required for the testsuite to pass.
    # SimpleCov will return non-zero if the current coverage of the least covered file
    # is below this threshold.
    #
    # Default is 0% (disabled)
    #
    def minimum_coverage_by_file(coverage = nil)
      return @minimum_coverage_by_file ||= {} unless coverage

      coverage = {primary_coverage => coverage} if coverage.is_a?(Numeric)

      raise_on_invalid_coverage(coverage, "minimum_coverage_by_file")

      @minimum_coverage_by_file = coverage
    end

    #
    # Refuses any coverage drop. That is, coverage is only allowed to increase.
    # SimpleCov will return non-zero if the coverage decreases.
    #
    def refuse_coverage_drop(*criteria)
      criteria = coverage_criteria if criteria.empty?

      maximum_coverage_drop(criteria.map { |c| [c, 0] }.to_h)
    end

    #
    # Add a filter to the processing chain.
    # There are four ways to define a filter:
    #
    # * as a String that will then be matched against all source files' file paths,
    #     SimpleCov.add_filter 'app/models' # will reject all your models
    # * as a block which will be passed the source file in question and should either
    #   return a true or false value, depending on whether the file should be removed
    #     SimpleCov.add_filter do |src_file|
    #       File.basename(src_file.filename) == 'environment.rb'
    #     end # Will exclude environment.rb files from the results
    # * as an array of strings that are matched against all sorce files' file
    #   paths and then ignored (basically string filter multiple times)
    #     SimpleCov.add_filter ['app/models', 'app/helpers'] # ignores both dirs
    # * as an instance of a subclass of SimpleCov::Filter. See the documentation there
    #   on how to define your own filter classes
    #
    def add_filter(filter_argument = nil, &filter_proc)
      filters << parse_filter(filter_argument, &filter_proc)
    end

    #
    # Define a group for files. Works similar to add_filter, only that the first
    # argument is the desired group name and files PASSING the filter end up in the group
    # (while filters exclude when the filter is applicable).
    #
    def add_group(group_name, filter_argument = nil, &filter_proc)
      groups[group_name] = parse_filter(filter_argument, &filter_proc)
    end

    SUPPORTED_COVERAGE_CRITERIA = %i[line branch].freeze
    DEFAULT_COVERAGE_CRITERION = :line
    #
    # Define which coverage criterion should be evaluated.
    #
    # Possible coverage criteria:
    # * :line - coverage based on lines aka has this line been executed?
    # * :branch - coverage based on branches aka has this branch (think conditions) been executed?
    #
    # If not set the default is `:line`
    #
    # @param [Symbol] criterion
    #
    def coverage_criterion(criterion = nil)
      return @coverage_criterion ||= primary_coverage unless criterion

      raise_if_criterion_unsupported(criterion)

      @coverage_criterion = criterion
    end

    def enable_coverage(criterion)
      raise_if_criterion_unsupported(criterion)

      coverage_criteria << criterion
    end

    def primary_coverage(criterion = nil)
      if criterion.nil?
        @primary_coverage ||= DEFAULT_COVERAGE_CRITERION
      else
        raise_if_criterion_disabled(criterion)
        @primary_coverage = criterion
      end
    end

    def coverage_criteria
      @coverage_criteria ||= Set[primary_coverage]
    end

    def coverage_criterion_enabled?(criterion)
      coverage_criteria.member?(criterion)
    end

    def clear_coverage_criteria
      @coverage_criteria = nil
    end

    def branch_coverage?
      branch_coverage_supported? && coverage_criterion_enabled?(:branch)
    end

    def coverage_start_arguments_supported?
      # safe to cache as within one process this value should never
      # change
      return @coverage_start_arguments_supported if defined?(@coverage_start_arguments_supported)

      @coverage_start_arguments_supported = begin
        require "coverage"
        !Coverage.method(:start).arity.zero?
      end
    end

    def branch_coverage_supported?
      coverage_start_arguments_supported? && RUBY_ENGINE != "jruby"
    end

    def coverage_for_eval_supported?
      require "coverage"
      defined?(Coverage.supported?) && Coverage.supported?(:eval)
    end

    def coverage_for_eval_enabled?
      @coverage_for_eval_enabled ||= false
    end

    def enable_coverage_for_eval
      if coverage_for_eval_supported?
        @coverage_for_eval_enabled = true
      else
        warn "Coverage for eval is not available; Use Ruby 3.2.0 or later"
      end
    end

  private

    def raise_if_criterion_disabled(criterion)
      raise_if_criterion_unsupported(criterion)
      # rubocop:disable Style/IfUnlessModifier
      unless coverage_criterion_enabled?(criterion)
        raise "Coverage criterion #{criterion}, is disabled! Please enable it first through enable_coverage #{criterion} (if supported)"
      end
      # rubocop:enable Style/IfUnlessModifier
    end

    def raise_if_criterion_unsupported(criterion)
      # rubocop:disable Style/IfUnlessModifier
      unless SUPPORTED_COVERAGE_CRITERIA.member?(criterion)
        raise "Unsupported coverage criterion #{criterion}, supported values are #{SUPPORTED_COVERAGE_CRITERIA}"
      end
      # rubocop:enable Style/IfUnlessModifier
    end

    def minimum_possible_coverage_exceeded(coverage_option)
      warn "The coverage you set for #{coverage_option} is greater than 100%"
    end

    #
    # The actual filter processor. Not meant for direct use
    #
    def parse_filter(filter_argument = nil, &filter_proc)
      filter = filter_argument || filter_proc

      if filter
        SimpleCov::Filter.build_filter(filter)
      else
        raise ArgumentError, "Please specify either a filter or a block to filter with"
      end
    end
  end
end
