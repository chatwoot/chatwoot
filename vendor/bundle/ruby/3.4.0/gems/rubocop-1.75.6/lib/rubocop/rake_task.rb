# frozen_string_literal: true

require 'rake'
require 'rake/tasklib'

module RuboCop
  # Provides a custom rake task.
  #
  # require 'rubocop/rake_task'
  # RuboCop::RakeTask.new
  #
  # Use global Rake namespace here to avoid namespace issues with custom
  # rubocop-rake tasks
  class RakeTask < ::Rake::TaskLib
    attr_accessor :name, :verbose, :fail_on_error, :patterns, :formatters, :plugins, :requires,
                  :options

    def initialize(name = :rubocop, *args, &task_block)
      super()
      setup_ivars(name)

      desc 'Run RuboCop' unless ::Rake.application.last_description

      task(name, *args) do |_, task_args|
        RakeFileUtils.verbose(verbose) do
          yield(*[self, task_args].slice(0, task_block.arity)) if task_block
          run_cli(verbose, full_options)
        end
      end

      setup_subtasks(name, *args, &task_block)
    end

    private

    def perform(option)
      options = full_options.unshift(option)
      # `parallel` will automatically be removed from the options internally.
      # This is a nice to have to suppress the warning message
      # about --parallel and --autocorrect not being compatible.
      options.delete('--parallel')
      run_cli(verbose, options)
    end

    def run_cli(verbose, options)
      # We lazy-load RuboCop so that the task doesn't dramatically impact the
      # load time of your Rakefile.
      require_relative '../rubocop'

      cli = CLI.new
      puts 'Running RuboCop...' if verbose
      result = cli.run(options)
      abort('RuboCop failed!') if result.nonzero? && fail_on_error
    end

    def full_options
      formatters.map { |f| ['--format', f] }.flatten
                .concat(plugins.map { |plugin| ['--plugin', plugin] }.flatten)
                .concat(requires.map { |r| ['--require', r] }.flatten)
                .concat(options.flatten)
                .concat(patterns)
    end

    def setup_ivars(name)
      @name = name
      @verbose = true
      @fail_on_error = true
      @patterns = []
      @plugins = []
      @requires = []
      @options = []
      @formatters = []
    end

    def setup_subtasks(name, *args, &task_block) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      namespace(name) do
        # rubocop:todo Naming/InclusiveLanguage
        task(:auto_correct, *args) do
          require 'rainbow'
          warn Rainbow(
            'rubocop:auto_correct task is deprecated; ' \
            'use rubocop:autocorrect task or rubocop:autocorrect_all task instead.'
          ).yellow
          RakeFileUtils.verbose(verbose) do
            yield(*[self, task_args].slice(0, task_block.arity)) if task_block
            perform('--autocorrect')
          end
        end
        # rubocop:enable Naming/InclusiveLanguage

        desc "Autocorrect RuboCop offenses (only when it's safe)."
        task(:autocorrect, *args) do |_, task_args|
          RakeFileUtils.verbose(verbose) do
            yield(*[self, task_args].slice(0, task_block.arity)) if task_block
            perform('--autocorrect')
          end
        end

        desc 'Autocorrect RuboCop offenses (safe and unsafe).'
        task(:autocorrect_all, *args) do |_, task_args|
          RakeFileUtils.verbose(verbose) do
            yield(*[self, task_args].slice(0, task_block.arity)) if task_block
            perform('--autocorrect-all')
          end
        end
      end
    end
  end
end
