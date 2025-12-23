# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for ambiguous operators in the first argument of a
      # method invocation without parentheses.
      #
      # @example
      #
      #   # bad
      #
      #   # The `*` is interpreted as a splat operator but it could possibly be
      #   # a `*` method invocation (i.e. `do_something.*(some_array)`).
      #   do_something *some_array
      #
      #   # good
      #
      #   # With parentheses, there's no ambiguity.
      #   do_something(*some_array)
      class AmbiguousOperator < Base
        extend AutoCorrector

        AMBIGUITIES = {
          '+'  => { actual: 'positive number', possible: 'an addition' },
          '-'  => { actual: 'negative number', possible: 'a subtraction' },
          '*'  => { actual: 'splat',           possible: 'a multiplication' },
          '&'  => { actual: 'block',           possible: 'a binary AND' },
          '**' => { actual: 'keyword splat',   possible: 'an exponent' }
        }.each do |key, hash|
          hash[:operator] = key
        end

        MSG_FORMAT = 'Ambiguous %<actual>s operator. Parenthesize the method ' \
                     "arguments if it's surely a %<actual>s operator, or add " \
                     'a whitespace to the right of the `%<operator>s` if it ' \
                     'should be %<possible>s.'

        def self.autocorrect_incompatible_with
          [Naming::BlockForwarding]
        end

        def on_new_investigation
          processed_source.diagnostics.each do |diagnostic|
            next unless diagnostic.reason == :ambiguous_prefix

            offense_node = find_offense_node_by(diagnostic)
            next unless offense_node

            message = message(diagnostic)

            add_offense(
              diagnostic.location, message: message, severity: diagnostic.level
            ) do |corrector|
              add_parentheses(offense_node, corrector)
            end
          end
        end

        private

        def find_offense_node_by(diagnostic)
          ast = processed_source.ast
          ast.each_node(:splat, :block_pass, :kwsplat) do |node|
            next unless offense_position?(node, diagnostic)

            offense_node = offense_node(node)
            return offense_node if offense_node
          end

          ast.each_node(:send).find do |send_node|
            first_argument = send_node.first_argument

            first_argument &&
              offense_position?(first_argument, diagnostic) &&
              unary_operator?(first_argument, diagnostic)
          end
        end

        def message(diagnostic)
          operator = diagnostic.location.source
          hash = AMBIGUITIES[operator]
          format(MSG_FORMAT, hash)
        end

        def offense_position?(node, diagnostic)
          node.source_range.begin_pos == diagnostic.location.begin_pos
        end

        def offense_node(node)
          case node.type
          when :splat, :block_pass
            node.parent
          when :kwsplat
            node.parent.parent
          end
        end

        def unary_operator?(node, diagnostic)
          node.source.start_with?(diagnostic.arguments[:prefix])
        end
      end
    end
  end
end
