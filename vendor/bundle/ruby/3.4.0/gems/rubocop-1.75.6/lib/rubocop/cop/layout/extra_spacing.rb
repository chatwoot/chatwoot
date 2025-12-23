# frozen_string_literal: true

module RuboCop
  module Cop
    module Layout
      # Checks for extra/unnecessary whitespace.
      #
      # @example
      #
      #   # good if AllowForAlignment is true
      #   name      = "RuboCop"
      #   # Some comment and an empty line
      #
      #   website  += "/rubocop/rubocop" unless cond
      #   puts        "rubocop"          if     debug
      #
      #   # bad for any configuration
      #   set_app("RuboCop")
      #   website  = "https://github.com/rubocop/rubocop"
      #
      #   # good only if AllowBeforeTrailingComments is true
      #   object.method(arg)  # this is a comment
      #
      #   # good even if AllowBeforeTrailingComments is false or not set
      #   object.method(arg) # this is a comment
      #
      #   # good with either AllowBeforeTrailingComments or AllowForAlignment
      #   object.method(arg)         # this is a comment
      #   another_object.method(arg) # this is another comment
      #   some_object.method(arg)    # this is some comment
      class ExtraSpacing < Base
        extend AutoCorrector
        include PrecedingFollowingAlignment
        include RangeHelp

        MSG_UNNECESSARY = 'Unnecessary spacing detected.'
        MSG_UNALIGNED_ASGN = '`=` is not aligned with the %<location>s assignment.'

        def on_new_investigation
          return if processed_source.blank?

          @aligned_comments = aligned_locations(processed_source.comments.map(&:loc))
          @corrected = Set.new if force_equal_sign_alignment?

          processed_source.tokens.each_cons(2) do |token1, token2|
            check_tokens(processed_source.ast, token1, token2)
          end
        end

        private

        def aligned_locations(locs)
          return [] if locs.empty?

          aligned = Set.new
          locs.each_cons(2) do |loc1, loc2|
            aligned << loc1.line << loc2.line if loc1.column == loc2.column
          end
          aligned
        end

        def check_tokens(ast, token1, token2)
          return if token2.type == :tNL

          if force_equal_sign_alignment? && assignment_tokens.include?(token2)
            check_assignment(token2)
          else
            check_other(token1, token2, ast)
          end
        end

        def check_assignment(token)
          return unless aligned_with_preceding_equals_operator(token) == :no

          message = format(MSG_UNALIGNED_ASGN, location: 'preceding')
          add_offense(token.pos, message: message) do |corrector|
            align_equal_signs(token.pos, corrector)
          end
        end

        def check_other(token1, token2, ast)
          return false if allow_for_trailing_comments? && token2.text.start_with?('#')

          extra_space_range(token1, token2) do |range|
            next if ignored_range?(ast, range.begin_pos)

            add_offense(range, message: MSG_UNNECESSARY) { |corrector| corrector.remove(range) }
          end
        end

        def extra_space_range(token1, token2)
          return if token1.line != token2.line

          start_pos = token1.end_pos
          end_pos = token2.begin_pos - 1
          return if end_pos <= start_pos

          return if allow_for_alignment? && aligned_tok?(token2)

          yield range_between(start_pos, end_pos)
        end

        def aligned_tok?(token)
          if token.comment?
            @aligned_comments.include?(token.line)
          else
            aligned_with_something?(token.pos)
          end
        end

        def ignored_range?(ast, start_pos)
          ignored_ranges(ast).any? { |r| r.include?(start_pos) }
        end

        # Returns an array of ranges that should not be reported. It's the
        # extra spaces between the keys and values in a multiline hash,
        # since those are handled by the Layout/HashAlignment cop.
        def ignored_ranges(ast)
          return [] unless ast

          @ignored_ranges ||= begin
            ranges = []
            on_node(:pair, ast) do |pair|
              next if pair.parent.single_line?

              key, value = *pair
              ranges << (key.source_range.end_pos...value.source_range.begin_pos)
            end
            ranges
          end
        end

        def force_equal_sign_alignment?
          cop_config['ForceEqualSignAlignment']
        end

        def align_equal_signs(range, corrector)
          lines  = all_relevant_assignment_lines(range.line)
          tokens = assignment_tokens.select { |t| lines.include?(t.line) }

          columns  = tokens.map { |t| align_column(t) }
          align_to = columns.max

          tokens.each { |token| align_equal_sign(corrector, token, align_to) }
        end

        def align_equal_sign(corrector, token, align_to)
          return unless @corrected.add?(token)

          diff = align_to - token.pos.last_column

          if diff.positive?
            corrector.insert_before(token.pos, ' ' * diff)
          elsif diff.negative?
            corrector.remove_preceding(token.pos, -diff)
          end
        end

        def all_relevant_assignment_lines(line_number)
          last_line_number = processed_source.lines.size

          (
            relevant_assignment_lines(line_number.downto(1)) +
            relevant_assignment_lines(line_number.upto(last_line_number))
          )
            .uniq
            .sort
        end

        def align_column(asgn_token)
          # if we removed unneeded spaces from the beginning of this =,
          # what column would it end from?
          line    = processed_source.lines[asgn_token.line - 1]
          leading = line[0...asgn_token.column]
          spaces  = leading.size - (leading =~ / *\Z/)
          asgn_token.pos.last_column - spaces + 1
        end

        def allow_for_trailing_comments?
          cop_config['AllowBeforeTrailingComments']
        end
      end
    end
  end
end
