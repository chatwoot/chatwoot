# frozen_string_literal: true

require 'tsort'

module RuboCop
  module Cop
    module Style
      # Checks for simple usages of parallel assignment.
      # This will only complain when the number of variables
      # being assigned matched the number of assigning variables.
      #
      # @example
      #   # bad
      #   a, b, c = 1, 2, 3
      #   a, b, c = [1, 2, 3]
      #
      #   # good
      #   one, two = *foo
      #   a, b = foo()
      #   a, b = b, a
      #
      #   a = 1
      #   b = 2
      #   c = 3
      class ParallelAssignment < Base
        include RescueNode
        extend AutoCorrector

        MSG = 'Do not use parallel assignment.'

        def on_masgn(node) # rubocop:disable Metrics/AbcSize
          rhs = node.rhs
          rhs = rhs.body if rhs.rescue_type?
          rhs_elements = Array(rhs).compact # edge case for one constant

          return if allowed_lhs?(node.assignments) || allowed_rhs?(rhs) ||
                    allowed_masign?(node.assignments, rhs_elements)

          range = node.source_range.begin.join(rhs.source_range.end)

          add_offense(range) do |corrector|
            autocorrect(corrector, node, rhs)
          end
        end

        private

        def autocorrect(corrector, node, rhs)
          order = find_valid_order(node.assignments, Array(rhs).compact)
          correction = assignment_corrector(node, rhs, order)

          corrector.replace(correction.correction_range, correction.correction)
        end

        def allowed_masign?(lhs_elements, rhs_elements)
          lhs_elements.size != rhs_elements.size ||
            !find_valid_order(lhs_elements,
                              add_self_to_getters(rhs_elements))
        end

        def allowed_lhs?(elements)
          # Account for edge cases using one variable with a comma
          # E.g.: `foo, = *bar`
          elements.one? || elements.any?(&:splat_type?)
        end

        def allowed_rhs?(node)
          # Edge case for one constant
          elements = Array(node).compact

          # Account for edge case of `Constant::CONSTANT`
          !node.array_type? || elements.any?(&:splat_type?)
        end

        def assignment_corrector(node, rhs, order)
          if node.parent&.rescue_type?
            _assignment, modifier = *node.parent
          else
            _assignment, modifier = *rhs.parent
          end

          if modifier_statement?(node.parent)
            ModifierCorrector.new(node, rhs, modifier, config, order)
          elsif rescue_modifier?(modifier)
            RescueCorrector.new(node, rhs, modifier, config, order)
          else
            GenericCorrector.new(node, rhs, modifier, config, order)
          end
        end

        def find_valid_order(left_elements, right_elements)
          # arrange left_elements in an order such that no corresponding right
          # element refers to a left element earlier in the sequence
          # this can be done using an algorithm called a "topological sort"
          # fortunately for us, Ruby's stdlib contains an implementation
          assignments = left_elements.zip(right_elements)

          begin
            AssignmentSorter.new(assignments).tsort
          rescue TSort::Cyclic
            nil
          end
        end

        # Converts (send nil :something) nodes to (send (:self) :something).
        # This makes the sorting algorithm work for expressions such as
        # `self.a, self.b = b, a`.
        def add_self_to_getters(right_elements)
          right_elements.map do |e|
            implicit_self_getter?(e) { |var| s(:send, s(:self), var) } || e
          end
        end

        # @!method implicit_self_getter?(node)
        def_node_matcher :implicit_self_getter?, '(send nil? $_)'

        # Helper class necessitated by silly design of TSort prior to Ruby 2.1
        # Newer versions have a better API, but that doesn't help us
        class AssignmentSorter
          include TSort
          extend RuboCop::NodePattern::Macros

          # @!method var_name(node)
          def_node_matcher :var_name, '{(casgn _ $_) (_ $_)}'

          # @!method uses_var?(node)
          def_node_search :uses_var?, '{({lvar ivar cvar gvar} %) (const _ %)}'

          # @!method matching_calls(node, receiver, method_name)
          def_node_search :matching_calls, '(send %1 %2 $...)'

          def initialize(assignments)
            @assignments = assignments
          end

          def tsort_each_node(...)
            @assignments.each(...)
          end

          def tsort_each_child(assignment)
            # yield all the assignments which must come after `assignment`
            # (due to dependencies on the previous value of the assigned var)
            my_lhs, _my_rhs = *assignment

            @assignments.each do |other|
              _other_lhs, other_rhs = *other

              next unless dependency?(my_lhs, other_rhs)

              yield other
            end
          end

          def dependency?(lhs, rhs)
            uses_var?(rhs, var_name(lhs)) ||
              (lhs.send_type? && lhs.assignment_method? && accesses?(rhs, lhs))
          end

          # `lhs` is an assignment method call like `obj.attr=` or `ary[idx]=`.
          # Does `rhs` access the same value which is assigned by `lhs`?
          def accesses?(rhs, lhs)
            if lhs.method?(:[]=)
              # FIXME: Workaround `rubocop:disable` comment for JRuby.
              # rubocop:disable Performance/RedundantEqualityComparisonBlock
              matching_calls(rhs, lhs.receiver, :[]).any? { |args| args == lhs.arguments }
              # rubocop:enable Performance/RedundantEqualityComparisonBlock
            else
              access_method = lhs.method_name.to_s.chop.to_sym
              matching_calls(rhs, lhs.receiver, access_method).any?
            end
          end
        end

        def modifier_statement?(node)
          return false unless node

          node.basic_conditional? && node.modifier_form?
        end

        # An internal class for correcting parallel assignment
        class GenericCorrector
          include Alignment

          attr_reader :node, :rhs, :rescue_result, :config

          def initialize(node, rhs, modifier, config, new_elements)
            @node = node
            @rhs = rhs
            _, _, @rescue_result = *modifier
            @config = config
            @new_elements = new_elements
          end

          def correction
            assignment.join("\n#{offset(node)}")
          end

          def correction_range
            node.source_range
          end

          protected

          def assignment
            @new_elements.map { |lhs, rhs| "#{lhs.source} = #{source(rhs, rhs.loc)}" }
          end

          private

          def source(node, loc)
            # __FILE__ is treated as a StrNode but has no begin
            if node.str_type? && loc.respond_to?(:begin) && loc.begin.nil?
              "'#{node.source}'"
            elsif node.sym_type? && loc.begin.nil?
              ":#{node.source}"
            else
              node.source
            end
          end

          def extract_sources(node)
            node.children.map(&:source)
          end

          def cop_config
            @config.for_cop('Style/ParallelAssignment')
          end
        end

        # An internal class for correcting parallel assignment
        # protected by rescue
        class RescueCorrector < GenericCorrector
          def correction
            # If the parallel assignment uses a rescue modifier and it is the
            # only contents of a method, then we want to make use of the
            # implicit begin
            if rhs.parent.parent.parent&.def_type?
              super + def_correction(rescue_result)
            else
              begin_correction(rescue_result)
            end
          end

          def correction_range
            rhs.parent.parent.source_range
          end

          private

          def def_correction(rescue_result)
            "\nrescue" \
              "\n#{offset(node)}#{rescue_result.source}"
          end

          def begin_correction(rescue_result)
            "begin\n" \
              "#{indentation(node)}" \
              "#{assignment.join("\n#{indentation(node)}")}" \
              "\n#{offset(node)}rescue\n" \
              "#{indentation(node)}#{rescue_result.source}" \
              "\n#{offset(node)}end"
          end
        end

        # An internal class for correcting parallel assignment
        # guarded by if, unless, while, or until
        class ModifierCorrector < GenericCorrector
          def correction
            parent = node.parent

            "#{modifier_range(parent).source}\n" \
              "#{indentation(node)}" \
              "#{assignment.join("\n#{indentation(node)}")}" \
              "\n#{offset(node)}end"
          end

          def correction_range
            node.parent.source_range
          end

          private

          def modifier_range(node)
            node.loc.keyword.join(node.source_range.end)
          end
        end
      end
    end
  end
end
