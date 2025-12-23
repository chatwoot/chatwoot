# frozen_string_literal: true

module RuboCop
  class CLI
    module Command
      # Run all the selected cops and report the result.
      # @api private
      class ExecuteRunner < Base
        include Formatter::TextUtil

        # Combination of short and long formatter names.
        INTEGRATION_FORMATTERS = %w[h html j json ju junit].freeze

        self.command_name = :execute_runner

        def run
          execute_runner(@paths)
        end

        private

        def execute_runner(paths)
          runner = Runner.new(@options, @config_store)

          all_pass_or_excluded = with_redirect do
            all_passed = runner.run(paths)
            display_summary(runner)
            all_passed || @options[:auto_gen_config]
          end

          maybe_print_corrected_source

          if runner.aborting?
            STATUS_INTERRUPTED
          elsif all_pass_or_excluded && runner.errors.empty?
            STATUS_SUCCESS
          else
            STATUS_OFFENSES
          end
        end

        def with_redirect
          if @options[:stderr]
            orig_stdout = $stdout
            begin
              $stdout = $stderr
              yield
            ensure
              $stdout = orig_stdout
            end
          else
            yield
          end
        end

        def display_summary(runner)
          display_warning_summary(runner.warnings)
          display_error_summary(runner.errors)
        end

        def display_warning_summary(warnings)
          return if warnings.empty?

          warn Rainbow("\n#{pluralize(warnings.size, 'warning')}:").yellow

          warnings.each { |warning| warn warning }
        end

        def display_error_summary(errors)
          return if errors.empty?

          warn Rainbow("\n#{pluralize(errors.size, 'error')} occurred:").red

          errors.each { |error| warn Rainbow(error).red }

          warn Rainbow(<<~WARNING.strip).yellow
            Errors are usually caused by RuboCop bugs.
            Please, update to the latest RuboCop version if not already in use, and report a bug if the issue still occurs on this version.
            #{bug_tracker_uri}
            Mention the following information in the issue report:
            #{RuboCop::Version.verbose}
          WARNING
        end

        def bug_tracker_uri
          return unless Gem.loaded_specs.key?('rubocop')

          "#{Gem.loaded_specs['rubocop'].metadata['bug_tracker_uri']}\n"
        end

        def maybe_print_corrected_source
          # Integration tools (like RubyMine) expect to have only the JSON result
          # when specifying JSON format. Similar HTML and JUnit are targeted as well.
          # See: https://github.com/rubocop/rubocop/issues/8673
          return if INTEGRATION_FORMATTERS.include?(@options[:format])

          return unless @options[:stdin] && @options[:autocorrect]

          (@options[:stderr] ? $stderr : $stdout).puts '=' * 20
          print @options[:stdin]
        end
      end
    end
  end
end
