# frozen_string_literal: true

module SCSSLint
  # Checks for space around operators on values.
  class Linter::SpaceAroundOperator < Linter
    include LinterRegistry

    def visit_script_operation(node)
      operation_sources = OperationSources.new(node, self)
      operation_sources.adjust_sources

      # When an operation is found interpolated within something not a String
      # (only selectors?), the source ranges are offset by two (probably not
      # accounting for the `#{`. Slide everything to the left by 2, and maybe
      # things will look sane this time.
      unless operation_sources.operator_source.match?(Sass::Script::Lexer::REGULAR_EXPRESSIONS[:op])
        operation_sources.adjust_for_interpolation
        operation_sources.adjust_sources
      end

      check(node, operation_sources)

      yield
    end

    # Making a public version of #source_from_range, a private method.
    def source_fm_range(range)
      source_from_range(range)
    end

  private

    def check(node, operation_sources) # rubocop:disable Metrics/AbcSize, Metrics/LineLength, Metrics/MethodLength
      match = operation_sources.operator_source.match(/
        (?<left_space>\s*)
        (?<operator>\S+)
        (?<right_space>\s*)
      /x)

      # We forgive spacing with newlines. In the case of a newline occurring on
      # one side or another, we don't care about indentation, and the
      # TrailingWhitespace linter will worry about trailing whitespace, so we
      # just don't worry about space with a newline.
      left_newline = match[:left_space].include?("\n")
      right_newline = match[:right_space].include?("\n")

      case config['style']
      when 'one_space'
        if one_space_exists?(match, left_newline, right_newline)
          add_lint(node, operation_sources.space_msg(match[:operator]))
        end
      when 'at_least_one_space'
        unless spaces_exist?(match, left_newline, right_newline)
          add_lint(node, operation_sources.space_msg(match[:operator]))
        end
      else
        if spaces_exist?(match, left_newline, right_newline)
          add_lint(node, operation_sources.no_space_msg(match[:operator]))
        end
      end
    end

    def one_space_exists?(match, left_newline, right_newline)
      (match[:left_space] != ' ' && !left_newline) ||
        (match[:right_space] != ' ' && !right_newline)
    end

    def spaces_exist?(match, left_newline, right_newline)
      (match[:left_space] != '' && !left_newline) ||
        (match[:right_space] != '' && !right_newline)
    end

    # A helper class for storing and adjusting the sources of the different
    # components of an Operation node.
    class OperationSources
      attr_reader :operator_source

      def initialize(node, linter)
        @node = node
        @linter = linter
        @source = normalize_source(@linter.source_fm_range(@node.source_range))
        @left_range = @node.operand1.source_range
        @right_range = @node.operand2.source_range
      end

      def adjust_sources
        # We need to #chop at the end because an operation's operand1 _always_
        # includes one character past the actual operand (which is either a
        # whitespace character, or the first character of the operation).
        @left_source = normalize_source(@linter.source_fm_range(@left_range))
        @right_source = normalize_source(@linter.source_fm_range(@right_range))
        @operator_source = calculate_operator_source
        adjust_left_boundary
      end

      def adjust_for_interpolation
        @source = normalize_source(@linter.source_fm_range(slide_to_the_left(@node.source_range)))
        @left_range = slide_to_the_left(@node.operand1.source_range)
        @right_range = slide_to_the_left(@node.operand2.source_range)
      end

      def space_msg(operator)
        SPACE_MSG % [@source, @left_source, operator, @right_source]
      end

      def no_space_msg(operator)
        NO_SPACE_MSG % [@source, @left_source, operator, @right_source]
      end

    private

      SPACE_MSG = '`%s` should be written with a single space on each side of ' \
                  'the operator: `%s %s %s`'.freeze

      NO_SPACE_MSG = '`%s` should be written without spaces around the ' \
                     'operator: `%s%s%s`'.freeze

      def calculate_operator_source
        # We don't want to add 1 to range1.end_pos.offset for the same reason as
        # the #chop comment above.
        between_start = Sass::Source::Position.new(
          @left_range.end_pos.line,
          @left_range.end_pos.offset,
        )
        between_end = Sass::Source::Position.new(
          @right_range.start_pos.line,
          @right_range.start_pos.offset - 1,
        )

        @linter.source_fm_range(Sass::Source::Range.new(between_start,
                                                        between_end,
                                                        @left_range.file,
                                                        @left_range.importer))
      end

      def adjust_left_boundary
        # If the left operand is wrapped in parentheses, any right parens end up
        # in the operator source. Here, we move them into the left operand
        # source, which is awkward in any messaging, but it works.
        if match = @operator_source.match(/^(\s*\))+/)
          @left_source += match[0]
          @operator_source = @operator_source[match.end(0)..-1]
        end

        # If the left operand is a nested operation, Sass includes any whitespace
        # before the (outer) operator in the left operator's source_range's
        # end_pos, which is not the case with simple, non-operation operands.
        if match = @left_source.match(/\s+$/)
          @left_source = @left_source[0..match.begin(0)]
          @operator_source = match[0] + @operator_source
        end

        [@left_source, @operator_source]
      end

      # Removes trailing parentheses and compacts newlines into a single space
      def normalize_source(source)
        source.chop.gsub(/\s*\n\s*/, ' ')
      end

      def slide_to_the_left(range)
        start_pos = Sass::Source::Position.new(range.start_pos.line, range.start_pos.offset - 2)
        end_pos = Sass::Source::Position.new(range.end_pos.line, range.end_pos.offset - 2)
        Sass::Source::Range.new(start_pos, end_pos, range.file, range.importer)
      end
    end
  end
end
