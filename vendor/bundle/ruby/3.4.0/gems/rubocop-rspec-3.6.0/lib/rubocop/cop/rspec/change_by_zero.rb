# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Prefer negated matchers over `to change.by(0)`.
      #
      # In the case of composite expectations, cop suggest using the
      # negation matchers of `RSpec::Matchers#change`.
      #
      # By default the cop does not support autocorrect of
      # compound expectations, but if you set the
      # negated matcher for `change`, e.g. `not_change` with
      # the `NegatedMatcher` option, the cop will perform the autocorrection.
      #
      # @example NegatedMatcher: ~ (default)
      #   # bad
      #   expect { run }.to change(Foo, :bar).by(0)
      #   expect { run }.to change { Foo.bar }.by(0)
      #
      #   # bad - compound expectations (does not support autocorrection)
      #   expect { run }
      #     .to change(Foo, :bar).by(0)
      #     .and change(Foo, :baz).by(0)
      #   expect { run }
      #     .to change { Foo.bar }.by(0)
      #     .and change { Foo.baz }.by(0)
      #
      #   # good
      #   expect { run }.not_to change(Foo, :bar)
      #   expect { run }.not_to change { Foo.bar }
      #
      #   # good - compound expectations
      #   define_negated_matcher :not_change, :change
      #   expect { run }
      #     .to not_change(Foo, :bar)
      #     .and not_change(Foo, :baz)
      #   expect { run }
      #     .to not_change { Foo.bar }
      #     .and not_change { Foo.baz }
      #
      # @example NegatedMatcher: not_change
      #   # bad (support autocorrection to good case)
      #   expect { run }
      #     .to change(Foo, :bar).by(0)
      #     .and change(Foo, :baz).by(0)
      #   expect { run }
      #     .to change { Foo.bar }.by(0)
      #     .and change { Foo.baz }.by(0)
      #
      #   # good
      #   define_negated_matcher :not_change, :change
      #   expect { run }
      #     .to not_change(Foo, :bar)
      #     .and not_change(Foo, :baz)
      #   expect { run }
      #     .to not_change { Foo.bar }
      #     .and not_change { Foo.baz }
      #
      class ChangeByZero < Base
        extend AutoCorrector
        include RangeHelp

        MSG = 'Prefer `not_to change` over `to %<method>s.by(0)`.'
        MSG_COMPOUND = 'Prefer %<preferred>s with compound expectations ' \
                       'over `%<method>s.by(0)`.'
        CHANGE_METHODS = Set[:change, :a_block_changing, :changing].freeze
        RESTRICT_ON_SEND = CHANGE_METHODS.freeze

        # @!method expect_change_with_arguments(node)
        def_node_matcher :expect_change_with_arguments, <<~PATTERN
          (send
            $(send nil? CHANGE_METHODS ...) :by
            (int 0))
        PATTERN

        # @!method expect_change_with_block(node)
        def_node_matcher :expect_change_with_block, <<~PATTERN
          (send
            (block
              $(send nil? CHANGE_METHODS)
              (args)
              (send (...) _)) :by
            (int 0))
        PATTERN

        # @!method change_nodes(node)
        def_node_search :change_nodes, <<~PATTERN
          $(send nil? CHANGE_METHODS ...)
        PATTERN

        def on_send(node)
          expect_change_with_arguments(node.parent) do |change|
            register_offense(node.parent, change)
          end

          expect_change_with_block(node.parent.parent) do |change|
            register_offense(node.parent.parent, change)
          end
        end

        private

        def register_offense(node, change_node)
          return unless node.parent.send_type?

          if compound_expectations?(node)
            add_offense(node,
                        message: message_compound(change_node)) do |corrector|
              autocorrect_compound(corrector, node)
            end
          else
            add_offense(node,
                        message: message(change_node)) do |corrector|
              autocorrect(corrector, node, change_node)
            end
          end
        end

        def compound_expectations?(node)
          %i[and or & |].include?(node.parent.method_name)
        end

        def message(change_node)
          format(MSG, method: change_node.method_name)
        end

        def message_compound(change_node)
          format(MSG_COMPOUND, preferred: preferred_method,
                               method: change_node.method_name)
        end

        def autocorrect(corrector, node, change_node)
          corrector.replace(node.parent.loc.selector, 'not_to')
          corrector.replace(change_node.loc.selector, 'change')
          range = node.loc.dot.with(end_pos: node.source_range.end_pos)
          corrector.remove(range)
        end

        def autocorrect_compound(corrector, node)
          return unless negated_matcher

          change_nodes(node) do |change_node|
            corrector.replace(change_node.loc.selector, negated_matcher)
            insert_operator(corrector, node, change_node)
            remove_by_zero(corrector, node, change_node)
          end
        end

        def insert_operator(corrector, node, change_node)
          operator = node.right_siblings.first
          return unless %i[& |].include?(operator)

          corrector.insert_after(
            replace_node(node, change_node), " #{operator}"
          )
        end

        def replace_node(node, change_node)
          expect_change_with_arguments(node) ? change_node : change_node.parent
        end

        def remove_by_zero(corrector, node, change_node)
          range = node.loc.dot.with(end_pos: node.source_range.end_pos)
          if change_node.loc.line == range.line
            corrector.remove(range)
          else
            corrector.remove(
              range_by_whole_lines(range, include_final_newline: true)
            )
          end
        end

        def negated_matcher
          cop_config['NegatedMatcher']
        end

        def preferred_method
          negated_matcher ? "`#{negated_matcher}`" : 'negated matchers'
        end
      end
    end
  end
end
