# frozen_string_literal: true

RSpec::Support.require_rspec_core 'formatters/base_text_formatter'
RSpec::Support.require_rspec_core 'formatters/console_codes'

module RuboCop
  module RSpec
    # RSpec formatter for use with running `rake spec` in parallel. This formatter
    # removes much of the noise from RSpec so that only the important information
    # will be surfaced by test-queue.
    # It also adds metadata to the output in order to more easily find the text
    # needed for outputting after the parallel run completes.
    class ParallelFormatter < ::RSpec::Core::Formatters::BaseTextFormatter
      ::RSpec::Core::Formatters.register self, :dump_pending, :dump_failures, :dump_summary

      # Don't show pending tests
      def dump_pending(*); end

      # The BEGIN/END comments are used by `spec_runner.rake` to determine what
      # output goes where in the final parallelized output, and should not be
      # removed!
      def dump_failures(notification)
        return if notification.failure_notifications.empty?

        output.puts '# FAILURES BEGIN'
        notification.failure_notifications.each do |failure|
          output.puts failure.fully_formatted('*', colorizer)
        end
        output.puts
        output.puts '# FAILURES END'
      end

      def dump_summary(summary)
        output_summary(summary)
        output_rerun_commands(summary)
      end

      private

      def colorizer
        @colorizer ||= ::RSpec::Core::Formatters::ConsoleCodes
      end

      # The BEGIN/END comments are used by `spec_runner.rake` to determine what
      # output goes where in the final parallelized output, and should not be
      # removed!
      def output_summary(summary)
        output.puts '# SUMMARY BEGIN'
        output.puts colorize_summary(summary)
        output.puts '# SUMMARY END'
      end

      def colorize_summary(summary)
        totals = totals(summary)

        if summary.failure_count.positive? || summary.errors_outside_of_examples_count.positive?
          colorizer.wrap(totals, ::RSpec.configuration.failure_color)
        else
          colorizer.wrap(totals, ::RSpec.configuration.success_color)
        end
      end

      # The BEGIN/END comments are used by `spec_runner.rake` to determine what
      # output goes where in the final parallelized output, and should not be
      # removed!
      def output_rerun_commands(summary)
        output.puts '# RERUN BEGIN'
        output.puts summary.colorized_rerun_commands.lines[3..].join
        output.puts '# RERUN END'
      end

      def totals(summary)
        output = pluralize(summary.example_count, 'example')
        output += ", #{summary.pending_count} pending" if summary.pending_count.positive?
        output += ", #{pluralize(summary.failure_count, 'failure')}"

        if summary.errors_outside_of_examples_count.positive?
          error_count = pluralize(summary.errors_outside_of_examples_count, 'error')
          output += ", #{error_count} occurred outside of examples"
        end

        output
      end

      def pluralize(*args)
        ::RSpec::Core::Formatters::Helpers.pluralize(*args)
      end
    end
  end
end
