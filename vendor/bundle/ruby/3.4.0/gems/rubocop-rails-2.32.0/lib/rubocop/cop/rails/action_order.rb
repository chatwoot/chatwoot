# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Enforces consistent ordering of the standard Rails RESTful controller actions.
      #
      # The cop is configurable and can enforce any ordering of the standard actions.
      # All other methods are ignored. So, the actions specified in `ExpectedOrder` should be
      # defined before actions not specified.
      #
      # [source,yaml]
      # ----
      #  Rails/ActionOrder:
      #    ExpectedOrder:
      #      - index
      #      - show
      #      - new
      #      - edit
      #      - create
      #      - update
      #      - destroy
      # ----
      #
      # @example
      #   # bad
      #   def index; end
      #   def destroy; end
      #   def show; end
      #
      #   # good
      #   def index; end
      #   def show; end
      #   def destroy; end
      class ActionOrder < Base
        extend AutoCorrector
        include VisibilityHelp
        include DefNode
        include RangeHelp

        MSG = 'Action `%<current>s` should appear before `%<previous>s`.'

        def_node_search :action_declarations, '(def {%1} ...)'

        def on_class(node)
          action_declarations(node, actions).each_cons(2) do |previous, current|
            next if node_visibility(current) != :public || non_public?(current)
            next if find_index(current) >= find_index(previous)

            register_offense(previous, current)
          end
        end

        private

        def expected_order
          cop_config['ExpectedOrder'].map(&:to_sym)
        end

        def actions
          @actions ||= Set.new(expected_order)
        end

        def find_index(node)
          expected_order.find_index(node.method_name)
        end

        def register_offense(previous, current)
          message = format(
            MSG,
            expected_order: expected_order.join(', '),
            previous: previous.method_name,
            current: current.method_name
          )
          add_offense(current, message: message) do |corrector|
            current = correction_target(current)
            previous = correction_target(previous)

            swap_range(corrector, current, previous)
          end
        end

        def correction_target(def_node)
          range_with_comments_and_lines(def_node.each_ancestor(:if).first || def_node)
        end

        def add_range(range1, range2)
          range1.with(
            begin_pos: [range1.begin_pos, range2.begin_pos].min,
            end_pos: [range1.end_pos, range2.end_pos].max
          )
        end

        def range_with_comments(node)
          ranges = [node, *processed_source.ast_with_comments[node]].map(&:source_range)
          ranges.reduce do |result, range|
            add_range(result, range)
          end
        end

        def range_with_comments_and_lines(node)
          range_by_whole_lines(range_with_comments(node), include_final_newline: true)
        end

        def swap_range(corrector, range1, range2)
          corrector.insert_before(range2, range1.source)
          corrector.remove(range1)
        end
      end
    end
  end
end
