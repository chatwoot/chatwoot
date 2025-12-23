# frozen_string_literal: true

module RuboCop
  module Formatter
    # This formatter displays the report data in markdown
    class MarkdownFormatter < BaseFormatter
      include TextUtil
      include PathUtil
      attr_reader :files, :summary

      def initialize(output, options = {})
        super
        @files = []
        @summary = Struct.new(:offense_count, :inspected_files, :target_files).new(0)
      end

      def started(target_files)
        summary.target_files = target_files
      end

      def file_finished(file, offenses)
        files << Struct.new(:path, :offenses).new(file, offenses)
        summary.offense_count += offenses.count
      end

      def finished(inspected_files)
        summary.inspected_files = inspected_files
        render_markdown
      end

      private

      def render_markdown
        n_files = pluralize(summary.inspected_files.count, 'file')
        n_offenses = pluralize(summary.offense_count, 'offense', no_for_zero: true)

        output.write "# RuboCop Inspection Report\n\n"
        output.write "#{n_files} inspected, #{n_offenses} detected:\n\n"
        write_file_messages
      end

      def write_file_messages
        files.each do |file|
          next if file.offenses.empty?

          write_heading(file)
          file.offenses.each do |offense|
            write_context(offense)
            write_code(offense)
          end
        end
      end

      def write_heading(file)
        filename = relative_path(file.path)
        n_offenses = pluralize(file.offenses.count, 'offense')

        output.write "### #{filename} - (#{n_offenses})\n"
      end

      def write_context(offense)
        output.write(
          "  * **Line # #{offense.location.line} - #{offense.severity}:** #{offense.message}\n\n"
        )
      end

      def write_code(offense)
        code = offense.location.source_line + possible_ellipses(offense.location)

        output.write "    ```rb\n    #{code}\n    ```\n\n" unless code.blank?
      end

      def possible_ellipses(location)
        location.single_line? ? '' : ' ...'
      end
    end
  end
end
