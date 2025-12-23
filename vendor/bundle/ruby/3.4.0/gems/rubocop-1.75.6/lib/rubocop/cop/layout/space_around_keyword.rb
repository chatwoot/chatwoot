# frozen_string_literal: true

module RuboCop
  module Cop
    module Layout
      # Checks the spacing around the keywords.
      #
      # @example
      #
      #   # bad
      #   something 'test'do|x|
      #   end
      #
      #   while(something)
      #   end
      #
      #   something = 123if test
      #
      #   # good
      #   something 'test' do |x|
      #   end
      #
      #   while (something)
      #   end
      #
      #   something = 123 if test
      class SpaceAroundKeyword < Base
        extend AutoCorrector

        MSG_BEFORE = 'Space before keyword `%<range>s` is missing.'
        MSG_AFTER = 'Space after keyword `%<range>s` is missing.'

        DO = 'do'
        SAFE_NAVIGATION = '&.'
        NAMESPACE_OPERATOR = '::'
        ACCEPT_LEFT_PAREN = %w[break defined? next not rescue return super yield].freeze
        ACCEPT_LEFT_SQUARE_BRACKET = %w[super yield].freeze
        ACCEPT_NAMESPACE_OPERATOR = 'super'
        RESTRICT_ON_SEND = %i[!].freeze

        def on_and(node)
          check(node, [:operator].freeze) if node.keyword?
        end

        def on_block(node) # rubocop:disable InternalAffairs/NumblockHandler
          check(node, %i[begin end].freeze)
        end

        def on_break(node)
          check(node, [:keyword].freeze)
        end

        def on_case(node)
          check(node, %i[keyword else].freeze)
        end

        def on_case_match(node)
          check(node, %i[keyword else].freeze)
        end

        def on_ensure(node)
          check(node, [:keyword].freeze)
        end

        def on_for(node)
          check(node, %i[begin end].freeze)
        end

        def on_if(node)
          check(node, %i[keyword else begin end].freeze, 'then')
        end

        def on_if_guard(node)
          check(node, [:keyword].freeze)
        end

        def on_in_pattern(node)
          check(node, [:keyword].freeze)
        end

        def on_kwbegin(node)
          check(node, %i[begin end].freeze, nil)
        end

        # Handle one-line pattern matching syntax (`in`) with `Parser::Ruby27`.
        def on_match_pattern(node)
          return if target_ruby_version >= 3.0

          check(node, [:operator].freeze)
        end

        # Handle one-line pattern matching syntax (`in`) with `Parser::Ruby30`.
        def on_match_pattern_p(node)
          check(node, [:operator].freeze)
        end

        def on_next(node)
          check(node, [:keyword].freeze)
        end

        def on_or(node)
          check(node, [:operator].freeze) if node.keyword?
        end

        def on_postexe(node)
          check(node, [:keyword].freeze)
        end

        def on_preexe(node)
          check(node, [:keyword].freeze)
        end

        def on_resbody(node)
          check(node, [:keyword].freeze)
        end

        def on_rescue(node)
          check(node, [:else].freeze)
        end

        def on_return(node)
          check(node, [:keyword].freeze)
        end

        def on_send(node)
          check(node, [:selector].freeze) if node.prefix_not?
        end

        def on_super(node)
          check(node, [:keyword].freeze)
        end

        def on_zsuper(node)
          check(node, [:keyword].freeze)
        end

        def on_unless_guard(node)
          check(node, [:keyword].freeze)
        end

        def on_until(node)
          check(node, %i[begin end keyword].freeze)
        end

        def on_when(node)
          check(node, [:keyword].freeze)
        end

        def on_while(node)
          check(node, %i[begin end keyword].freeze)
        end

        def on_yield(node)
          check(node, [:keyword].freeze)
        end

        def on_defined?(node)
          check(node, [:keyword].freeze)
        end

        private

        def check(node, locations, begin_keyword = DO)
          locations.each do |loc|
            next unless node.loc.respond_to?(loc)

            range = node.loc.public_send(loc)
            next unless range

            case loc
            when :begin then check_begin(node, range, begin_keyword)
            when :end then check_end(node, range, begin_keyword)
            else check_keyword(node, range)
            end
          end
        end

        def check_begin(node, range, begin_keyword)
          return if begin_keyword && !range.is?(begin_keyword)

          check_keyword(node, range)
        end

        def check_end(node, range, begin_keyword)
          return if begin_keyword == DO && !do?(node)
          return unless space_before_missing?(range)

          add_offense(range, message: format(MSG_BEFORE, range: range.source)) do |corrector|
            corrector.insert_before(range, ' ')
          end
        end

        def do?(node)
          node.loc.begin&.is?(DO)
        end

        def check_keyword(node, range)
          if space_before_missing?(range) && !preceded_by_operator?(node, range)
            add_offense(range, message: format(MSG_BEFORE, range: range.source)) do |corrector|
              corrector.insert_before(range, ' ')
            end
          end

          return unless space_after_missing?(range)

          add_offense(range, message: format(MSG_AFTER, range: range.source)) do |corrector|
            corrector.insert_after(range, ' ')
          end
        end

        def space_before_missing?(range)
          pos = range.begin_pos - 1
          return false if pos.negative?

          !/[\s(|{\[;,*=]/.match?(range.source_buffer.source[pos])
        end

        def space_after_missing?(range)
          pos = range.end_pos
          char = range.source_buffer.source[pos]

          return false if accepted_opening_delimiter?(range, char)
          return false if safe_navigation_call?(range, pos)
          return false if accept_namespace_operator?(range) && namespace_operator?(range, pos)

          !/[\s;,#\\)}\].]/.match?(char)
        end

        def accepted_opening_delimiter?(range, char)
          return true unless char

          (accept_left_square_bracket?(range) && char == '[') ||
            (accept_left_parenthesis?(range) && char == '(')
        end

        def accept_left_parenthesis?(range)
          ACCEPT_LEFT_PAREN.include?(range.source)
        end

        def accept_left_square_bracket?(range)
          ACCEPT_LEFT_SQUARE_BRACKET.include?(range.source)
        end

        def accept_namespace_operator?(range)
          range.source == ACCEPT_NAMESPACE_OPERATOR
        end

        def safe_navigation_call?(range, pos)
          range.source_buffer.source[pos, 2].start_with?(SAFE_NAVIGATION)
        end

        def namespace_operator?(range, pos)
          range.source_buffer.source[pos, 2].start_with?(NAMESPACE_OPERATOR)
        end

        def preceded_by_operator?(node, _range)
          # regular dotted method calls bind more tightly than operators
          # so we need to climb up the AST past them
          node.each_ancestor do |ancestor|
            return true if ancestor.operator_keyword? || ancestor.range_type?
            return false unless ancestor.send_type?
            return true if ancestor.operator_method?
          end
          false
        end
      end
    end
  end
end
