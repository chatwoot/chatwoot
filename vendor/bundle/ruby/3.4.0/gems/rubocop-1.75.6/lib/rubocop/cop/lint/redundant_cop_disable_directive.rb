# frozen_string_literal: true

# The Lint/RedundantCopDisableDirective cop needs to be disabled so as
# to be able to provide a (bad) example of a redundant disable.
# rubocop:disable Lint/RedundantCopDisableDirective
module RuboCop
  module Cop
    module Lint
      # Detects instances of rubocop:disable comments that can be
      # removed without causing any offenses to be reported. It's implemented
      # as a cop in that it inherits from the Cop base class and calls
      # add_offense. The unusual part of its implementation is that it doesn't
      # have any on_* methods or an investigate method. This means that it
      # doesn't take part in the investigation phase when the other cops do
      # their work. Instead, it waits until it's called in a later stage of the
      # execution. The reason it can't be implemented as a normal cop is that
      # it depends on the results of all other cops to do its work.
      #
      #
      # @example
      #   # bad
      #   # rubocop:disable Layout/LineLength
      #   x += 1
      #   # rubocop:enable Layout/LineLength
      #
      #   # good
      #   x += 1
      class RedundantCopDisableDirective < Base # rubocop:todo Metrics/ClassLength
        include RangeHelp
        extend AutoCorrector

        COP_NAME = 'Lint/RedundantCopDisableDirective'
        DEPARTMENT_MARKER = 'DEPARTMENT'

        attr_accessor :offenses_to_check

        def initialize(config = nil, options = nil, offenses = nil)
          @offenses_to_check = offenses
          super(config, options)
        end

        def on_new_investigation
          return unless offenses_to_check

          redundant_cops = Hash.new { |h, k| h[k] = Set.new }

          each_redundant_disable do |comment, redundant_cop|
            redundant_cops[comment].add(redundant_cop)
          end

          add_offenses(redundant_cops)
          super
        end

        private

        def cop_disabled_line_ranges
          processed_source.disabled_line_ranges
        end

        def disabled_ranges
          cop_disabled_line_ranges[COP_NAME] || [0..0]
        end

        def previous_line_blank?(range)
          processed_source.buffer.source_line(range.line - 1).blank?
        end

        def comment_range_with_surrounding_space(directive_comment_range, line_comment_range)
          if previous_line_blank?(directive_comment_range) &&
             processed_source.comment_config.comment_only_line?(directive_comment_range.line) &&
             directive_comment_range.begin_pos == line_comment_range.begin_pos
            # When the previous line is blank, it should be retained
            range_with_surrounding_space(directive_comment_range, side: :right)
          else
            # Eat the entire comment, the preceding space, and the preceding
            # newline if there is one.
            original_begin = directive_comment_range.begin_pos
            range = range_with_surrounding_space(
              directive_comment_range, side: :left, newlines: true
            )

            range_with_surrounding_space(range,
                                         side: :right,
                                         # Special for a comment that
                                         # begins the file: remove
                                         # the newline at the end.
                                         newlines: original_begin.zero?)
          end
        end

        def directive_range_in_list(range, ranges)
          # Is there any cop between this one and the end of the line, which
          # is NOT being removed?
          if ends_its_line?(ranges.last) && trailing_range?(ranges, range)
            # Eat the comma on the left.
            range = range_with_surrounding_space(range, side: :left)
            range = range_with_surrounding_comma(range, :left)
          end

          range = range_with_surrounding_comma(range, :right)
          # Eat following spaces up to EOL, but not the newline itself.
          range_with_surrounding_space(range, side: :right, newlines: false)
        end

        def each_redundant_disable(&block)
          cop_disabled_line_ranges.each do |cop, line_ranges|
            each_already_disabled(cop, line_ranges, &block)
            each_line_range(cop, line_ranges, &block)
          end
        end

        def each_line_range(cop, line_ranges)
          line_ranges.each_with_index do |line_range, line_range_index|
            next if ignore_offense?(line_range)
            next if expected_final_disable?(cop, line_range)

            comment = processed_source.comment_at_line(line_range.begin)
            redundant = if all_disabled?(comment)
                          find_redundant_all(line_range, line_ranges[line_range_index + 1])
                        elsif department_disabled?(cop, comment)
                          find_redundant_department(cop, line_range)
                        else
                          find_redundant_cop(cop, line_range)
                        end

            yield comment, redundant if redundant
          end
        end

        # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        def each_already_disabled(cop, line_ranges)
          line_ranges.each_cons(2) do |previous_range, range|
            next if ignore_offense?(range)
            # If a cop is disabled in a range that begins on the same line as
            # the end of the previous range, it means that the cop was
            # already disabled by an earlier comment. So it's redundant
            # whether there are offenses or not.
            next unless followed_ranges?(previous_range, range)

            comment = processed_source.comment_at_line(range.begin)

            next unless comment
            # Comments disabling all cops don't count since it's reasonable
            # to disable a few select cops first and then all cops further
            # down in the code.
            next if all_disabled?(comment)

            redundant =
              if department_disabled?(cop, comment)
                find_redundant_department(cop, range)
              else
                cop
              end

            yield comment, redundant if redundant
          end
        end
        # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

        def find_redundant_cop(cop, range)
          cop_offenses = offenses_to_check.select { |offense| offense.cop_name == cop }
          cop if range_with_offense?(range, cop_offenses)
        end

        def find_redundant_all(range, next_range)
          # If there's a disable all comment followed by a comment
          # specifically disabling `cop`, we don't report the `all`
          # comment. If the disable all comment is truly redundant, we will
          # detect that when examining the comments of another cop, and we
          # get the full line range for the disable all.
          has_no_next_range = next_range.nil? || !followed_ranges?(range, next_range)
          'all' if has_no_next_range && range_with_offense?(range)
        end

        def find_redundant_department(cop, range)
          department = cop.split('/').first
          offenses = offenses_to_check.select { |offense| offense.cop_name.start_with?(department) }
          add_department_marker(department) if range_with_offense?(range, offenses)
        end

        def followed_ranges?(range, next_range)
          range.end == next_range.begin
        end

        def range_with_offense?(range, offenses = offenses_to_check)
          offenses.none? { |offense| range.cover?(offense.line) }
        end

        def all_disabled?(comment)
          DirectiveComment.new(comment).disabled_all?
        end

        def ignore_offense?(line_range)
          return true if line_range.min == CommentConfig::CONFIG_DISABLED_LINE_RANGE_MIN

          disabled_ranges.any? do |range|
            range.cover?(line_range.min) && range.cover?(line_range.max)
          end
        end

        def expected_final_disable?(cop, line_range)
          # A cop which is disabled in the config is being re-disabled until end of file
          cop_class = RuboCop::Cop::Registry.global.find_by_cop_name cop
          cop_class &&
            !processed_source.registry.enabled?(cop_class, config) &&
            line_range.max == Float::INFINITY
        end

        def department_disabled?(cop, comment)
          directive = DirectiveComment.new(comment)
          directive.in_directive_department?(cop) && !directive.overridden_by_department?(cop)
        end

        def directive_count(comment)
          DirectiveComment.new(comment).directive_count
        end

        def add_offenses(redundant_cops)
          redundant_cops.each do |comment, cops|
            if all_disabled?(comment) || directive_count(comment) == cops.size
              add_offense_for_entire_comment(comment, cops)
            else
              add_offense_for_some_cops(comment, cops)
            end
          end
        end

        def add_offense_for_entire_comment(comment, cops)
          location = DirectiveComment.new(comment).range
          cop_names = cops.sort.map { |c| describe(c) }.join(', ')

          add_offense(location, message: message(cop_names)) do |corrector|
            range = comment_range_with_surrounding_space(location, comment.source_range)

            if leave_free_comment?(comment, range)
              corrector.replace(range, ' # ')
            else
              corrector.remove(range)
            end
          end
        end

        def add_offense_for_some_cops(comment, cops)
          cop_ranges = cops.map { |c| [c, cop_range(comment, c)] }
          cop_ranges.sort_by! { |_, r| r.begin_pos }
          ranges = cop_ranges.map { |_, r| r }

          cop_ranges.each do |cop, range|
            cop_name = describe(cop)
            add_offense(range, message: message(cop_name)) do |corrector|
              range = directive_range_in_list(range, ranges)
              corrector.remove(range)
            end
          end
        end

        def leave_free_comment?(comment, range)
          free_comment = comment.text.gsub(range.source.strip, '')

          !free_comment.empty? && !free_comment.start_with?('#')
        end

        def cop_range(comment, cop)
          cop = remove_department_marker(cop)
          matching_range(comment.source_range, cop) ||
            matching_range(comment.source_range, Badge.parse(cop).cop_name) ||
            raise("Couldn't find #{cop} in comment: #{comment.text}")
        end

        def matching_range(haystack, needle)
          offset = haystack.source.index(needle)
          return unless offset

          offset += haystack.begin_pos
          Parser::Source::Range.new(haystack.source_buffer, offset, offset + needle.size)
        end

        def trailing_range?(ranges, range)
          ranges
            .drop_while { |r| !r.equal?(range) }
            .each_cons(2)
            .map { |range1, range2| range1.end.join(range2.begin).source }
            .all?(/\A\s*,\s*\z/)
        end

        SIMILAR_COP_NAMES_CACHE = Hash.new do |hash, cop_name|
          hash[:all_cop_names] = Registry.global.names unless hash.key?(:all_cop_names)
          hash[cop_name] = NameSimilarity.find_similar_name(cop_name, hash[:all_cop_names])
        end
        private_constant :SIMILAR_COP_NAMES_CACHE

        def describe(cop)
          return 'all cops' if cop == 'all'
          return "`#{remove_department_marker(cop)}` department" if department_marker?(cop)
          return "`#{cop}`" if all_cop_names.include?(cop)

          similar = SIMILAR_COP_NAMES_CACHE[cop]
          similar ? "`#{cop}` (did you mean `#{similar}`?)" : "`#{cop}` (unknown cop)"
        end

        def message(cop_names)
          "Unnecessary disabling of #{cop_names}."
        end

        def all_cop_names
          @all_cop_names ||= Registry.global.names
        end

        def ends_its_line?(range)
          line = range.source_buffer.source_line(range.last_line)
          (line =~ /\s*\z/) == range.last_column
        end

        def department_marker?(department)
          department.start_with?(DEPARTMENT_MARKER)
        end

        def remove_department_marker(department)
          department.gsub(DEPARTMENT_MARKER, '')
        end

        def add_department_marker(department)
          DEPARTMENT_MARKER + department
        end
      end
    end
  end
end
# rubocop:enable Lint/RedundantCopDisableDirective
