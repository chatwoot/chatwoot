# frozen_string_literal: true

module RuboCop
  module Cop
    module Metrics
      module Utils
        # > ABC is .. a software size metric .. computed by counting the number
        # > of assignments, branches and conditions for a section of code.
        # > http://c2.com/cgi/wiki?AbcMetric
        #
        # We separate the *calculator* from the *cop* so that the calculation,
        # the formula itself, is easier to test.
        class AbcSizeCalculator
          include IteratingBlock
          include RepeatedCsendDiscount
          prepend RepeatedAttributeDiscount

          # > Branch -- an explicit forward program branch out of scope -- a
          # > function call, class method call ..
          # > http://c2.com/cgi/wiki?AbcMetric
          BRANCH_NODES = %i[send csend yield].freeze

          # > Condition -- a logical/Boolean test, == != <= >= < > else case
          # > default try catch ? and unary conditionals.
          # > http://c2.com/cgi/wiki?AbcMetric
          CONDITION_NODES = CyclomaticComplexity::COUNTED_NODES.freeze

          private_constant :BRANCH_NODES, :CONDITION_NODES

          def self.calculate(node, discount_repeated_attributes: false)
            new(node, discount_repeated_attributes: discount_repeated_attributes).calculate
          end

          def initialize(node)
            @assignment = 0
            @branch = 0
            @condition = 0
            @node = node
            reset_repeated_csend
          end

          def calculate
            visit_depth_last(@node) { |child| calculate_node(child) }

            [
              Math.sqrt((@assignment**2) + (@branch**2) + (@condition**2)).round(2),
              "<#{@assignment}, #{@branch}, #{@condition}>"
            ]
          end

          def evaluate_branch_nodes(node)
            if node.comparison_method?
              @condition += 1
            else
              @branch += 1
              @condition += 1 if node.csend_type? && !discount_for_repeated_csend?(node)
            end
          end

          def evaluate_condition_node(node)
            @condition += 1 if else_branch?(node)
            @condition += 1
          end

          def else_branch?(node)
            %i[case if].include?(node.type) && node.else? && node.loc.else.is?('else')
          end

          private

          def visit_depth_last(node, &block)
            node.each_child_node { |child| visit_depth_last(child, &block) }
            yield node
          end

          def calculate_node(node)
            @assignment += 1 if assignment?(node)

            if branch?(node)
              evaluate_branch_nodes(node)
            elsif condition?(node)
              evaluate_condition_node(node)
            end
          end

          def assignment?(node)
            return compound_assignment(node) if node.masgn_type? || node.shorthand_asgn?

            node.for_type? ||
              (node.respond_to?(:setter_method?) && node.setter_method?) ||
              simple_assignment?(node) ||
              argument?(node)
          end

          def compound_assignment(node)
            # Methods setter cannot be detected for multiple assignments
            # and shorthand assigns, so we'll count them here instead
            children = node.masgn_type? ? node.assignments : node.children

            will_be_miscounted = children.count do |child|
              child.respond_to?(:setter_method?) && !child.setter_method?
            end
            @assignment += will_be_miscounted

            false
          end

          def simple_assignment?(node)
            if !node.equals_asgn?
              false
            elsif node.lvasgn_type?
              reset_on_lvasgn(node)
              capturing_variable?(node.children.first)
            else
              true
            end
          end

          def capturing_variable?(name)
            name && !name.start_with?('_')
          end

          def branch?(node)
            BRANCH_NODES.include?(node.type)
          end

          def argument?(node)
            node.argument_type? && capturing_variable?(node.children.first)
          end

          def condition?(node)
            return false if iterating_block?(node) == false

            CONDITION_NODES.include?(node.type)
          end
        end
      end
    end
  end
end
