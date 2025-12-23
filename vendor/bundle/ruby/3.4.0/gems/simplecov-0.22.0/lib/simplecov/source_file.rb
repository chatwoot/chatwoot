# frozen_string_literal: true

module SimpleCov
  #
  # Representation of a source file including it's coverage data, source code,
  # source lines and featuring helpers to interpret that data.
  #
  class SourceFile
    # The full path to this source file (e.g. /User/colszowka/projects/simplecov/lib/simplecov/source_file.rb)
    attr_reader :filename
    # The array of coverage data received from the Coverage.result
    attr_reader :coverage_data

    def initialize(filename, coverage_data)
      @filename = filename
      @coverage_data = coverage_data
    end

    # The path to this source file relative to the projects directory
    def project_filename
      @filename.delete_prefix(SimpleCov.root)
    end

    # The source code for this file. Aliased as :source
    def src
      # We intentionally read source code lazily to
      # suppress reading unused source code.
      @src ||= load_source
    end
    alias source src

    def coverage_statistics
      @coverage_statistics ||=
        {
          **line_coverage_statistics,
          **branch_coverage_statistics
        }
    end

    # Returns all source lines for this file as instances of SimpleCov::SourceFile::Line,
    # and thus including coverage data. Aliased as :source_lines
    def lines
      @lines ||= build_lines
    end
    alias source_lines lines

    # Returns all covered lines as SimpleCov::SourceFile::Line
    def covered_lines
      @covered_lines ||= lines.select(&:covered?)
    end

    # Returns all lines that should have been, but were not covered
    # as instances of SimpleCov::SourceFile::Line
    def missed_lines
      @missed_lines ||= lines.select(&:missed?)
    end

    # Returns all lines that are not relevant for coverage as
    # SimpleCov::SourceFile::Line instances
    def never_lines
      @never_lines ||= lines.select(&:never?)
    end

    # Returns all lines that were skipped as SimpleCov::SourceFile::Line instances
    def skipped_lines
      @skipped_lines ||= lines.select(&:skipped?)
    end

    # Returns the number of relevant lines (covered + missed)
    def lines_of_code
      coverage_statistics[:line]&.total
    end

    # Access SimpleCov::SourceFile::Line source lines by line number
    def line(number)
      lines[number - 1]
    end

    # The coverage for this file in percent. 0 if the file has no coverage lines
    def covered_percent
      coverage_statistics[:line]&.percent
    end

    def covered_strength
      coverage_statistics[:line]&.strength
    end

    def no_lines?
      lines.length.zero? || (lines.length == never_lines.size)
    end

    def relevant_lines
      lines.size - never_lines.size - skipped_lines.size
    end

    #
    # Return all the branches inside current source file
    def branches
      @branches ||= build_branches
    end

    def no_branches?
      total_branches.empty?
    end

    def branches_coverage_percent
      coverage_statistics[:branch]&.percent
    end

    #
    # Return the relevant branches to source file
    def total_branches
      @total_branches ||= covered_branches + missed_branches
    end

    #
    # Return hash with key of line number and branch coverage count as value
    def branches_report
      @branches_report ||= build_branches_report
    end

    #
    # Select the covered branches
    # Here we user tree schema because some conditions like case may have additional
    # else that is not in declared inside the code but given by default by coverage report
    #
    # @return [Array]
    #
    def covered_branches
      @covered_branches ||= branches.select(&:covered?)
    end

    #
    # Select the missed branches with coverage equal to zero
    #
    # @return [Array]
    #
    def missed_branches
      @missed_branches ||= branches.select(&:missed?)
    end

    def branches_for_line(line_number)
      branches_report.fetch(line_number, [])
    end

    #
    # Check if any branches missing on given line number
    #
    # @param [Integer] line_number
    #
    # @return [Boolean]
    #
    def line_with_missed_branch?(line_number)
      branches_for_line(line_number).select { |_type, count| count.zero? }.any?
    end

  private

    # no_cov_chunks is zero indexed to work directly with the array holding the lines
    def no_cov_chunks
      @no_cov_chunks ||= build_no_cov_chunks
    end

    def build_no_cov_chunks
      no_cov_lines = src.map.with_index(1).select { |line_src, _index| LinesClassifier.no_cov_line?(line_src) }

      # if we have an uneven number of nocovs we assume they go to the
      # end of the file, the source doesn't really matter
      # Can't deal with this within the each_slice due to differing
      # behavior in JRuby: jruby/jruby#6048
      no_cov_lines << ["", src.size] if no_cov_lines.size.odd?

      no_cov_lines.each_slice(2).map do |(_line_src_start, index_start), (_line_src_end, index_end)|
        index_start..index_end
      end
    end

    def load_source
      lines = []
      # The default encoding is UTF-8
      File.open(filename, "rb:UTF-8") do |file|
        current_line = file.gets

        if shebang?(current_line)
          lines << current_line
          current_line = file.gets
        end

        read_lines(file, lines, current_line)
      end
    end

    SHEBANG_REGEX = /\A#!/.freeze
    def shebang?(line)
      SHEBANG_REGEX.match?(line)
    end

    def read_lines(file, lines, current_line)
      return lines unless current_line

      set_encoding_based_on_magic_comment(file, current_line)
      lines.concat([current_line], ensure_remove_undefs(file.readlines))
    end

    RUBY_FILE_ENCODING_MAGIC_COMMENT_REGEX = /\A#\s*(?:-\*-)?\s*(?:en)?coding:\s*(\S+)\s*(?:-\*-)?\s*\z/.freeze
    def set_encoding_based_on_magic_comment(file, line)
      # Check for encoding magic comment
      # Encoding magic comment must be placed at first line except for shebang
      if (match = RUBY_FILE_ENCODING_MAGIC_COMMENT_REGEX.match(line))
        file.set_encoding(match[1], "UTF-8")
      end
    end

    def ensure_remove_undefs(file_lines)
      # invalid/undef replace are technically not really necessary but nice to
      # have and work around a JRuby incompatibility. Also moved here from
      # simplecov-html to have encoding shenaningans in one place. See #866
      # also setting these option on `file.set_encoding` doesn't seem to work
      # properly so it has to be done here.
      file_lines.each do |line|
        if line.encoding == Encoding::UTF_8
          line
        else
          line.encode!("UTF-8", invalid: :replace, undef: :replace)
        end
      end
    end

    def build_lines
      coverage_exceeding_source_warn if coverage_data["lines"].size > src.size
      lines = src.map.with_index(1) do |src, i|
        SimpleCov::SourceFile::Line.new(src, i, coverage_data["lines"][i - 1])
      end
      process_skipped_lines(lines)
    end

    def process_skipped_lines(lines)
      # the array the lines are kept in is 0-based whereas the line numbers in the nocov
      # chunks are 1-based and are expected to be like this in other parts (and it's also
      # arguably more understandable)
      no_cov_chunks.each { |chunk| lines[(chunk.begin - 1)..(chunk.end - 1)].each(&:skipped!) }

      lines
    end

    def lines_strength
      lines.sum { |line| line.coverage.to_i }
    end

    # Warning to identify condition from Issue #56
    def coverage_exceeding_source_warn
      warn "Warning: coverage data provided by Coverage [#{coverage_data['lines'].size}] exceeds number of lines in #{filename} [#{src.size}]"
    end

    #
    # Build full branches report
    # Root branches represent the wrapper of all condition state that
    # have inside the branches
    #
    # @return [Hash]
    #
    def build_branches_report
      branches.reject(&:skipped?).each_with_object({}) do |branch, coverage_statistics|
        coverage_statistics[branch.report_line] ||= []
        coverage_statistics[branch.report_line] << branch.report
      end
    end

    #
    # Call recursive method that transform our static hash to array of objects
    # @return [Array]
    #
    def build_branches
      coverage_branch_data = coverage_data.fetch("branches", {})
      branches = coverage_branch_data.flat_map do |condition, coverage_branches|
        build_branches_from(condition, coverage_branches)
      end

      process_skipped_branches(branches)
    end

    def process_skipped_branches(branches)
      return branches if no_cov_chunks.empty?

      branches.each do |branch|
        branch.skipped! if no_cov_chunks.any? { |no_cov_chunk| branch.overlaps_with?(no_cov_chunk) }
      end

      branches
    end

    # Since we are dumping to and loading from JSON, and we have arrays as keys those
    # don't make their way back to us intact e.g. just as a string
    #
    # We should probably do something different here, but as it stands these are
    # our data structures that we write so eval isn't _too_ bad.
    #
    # See #801
    #
    def restore_ruby_data_structure(structure)
      # Tests use the real data structures (except for integration tests) so no need to
      # put them through here.
      return structure if structure.is_a?(Array)

      # rubocop:disable Security/Eval
      eval structure
      # rubocop:enable Security/Eval
    end

    def build_branches_from(condition, branches)
      # the format handed in from the coverage data is like this:
      #
      #     [:then, 4, 6, 6, 6, 10]
      #
      # which is [type, id, start_line, start_col, end_line, end_col]
      _condition_type, _condition_id, condition_start_line, * = restore_ruby_data_structure(condition)

      branches.map do |branch_data, hit_count|
        branch_data = restore_ruby_data_structure(branch_data)
        build_branch(branch_data, hit_count, condition_start_line)
      end
    end

    def build_branch(branch_data, hit_count, condition_start_line)
      type, _id, start_line, _start_col, end_line, _end_col = branch_data

      SourceFile::Branch.new(
        start_line: start_line,
        end_line:   end_line,
        coverage:   hit_count,
        inline:     start_line == condition_start_line,
        type:       type
      )
    end

    def line_coverage_statistics
      {
        line: CoverageStatistics.new(
          total_strength: lines_strength,
          covered:  covered_lines.size,
          missed:   missed_lines.size
        )
      }
    end

    def branch_coverage_statistics
      {
        branch: CoverageStatistics.new(
          covered: covered_branches.size,
          missed:  missed_branches.size
        )
      }
    end
  end
end
