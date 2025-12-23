# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks constructors for disjunctive assignments (`||=`) that should
      # be plain assignments.
      #
      # So far, this cop is only concerned with disjunctive assignment of
      # instance variables.
      #
      # In ruby, an instance variable is nil until a value is assigned, so the
      # disjunction is unnecessary. A plain assignment has the same effect.
      #
      # @safety
      #   This cop is unsafe because it can register a false positive when a
      #   method is redefined in a subclass that calls super. For example:
      #
      #   [source,ruby]
      #   ----
      #   class Base
      #     def initialize
      #       @config ||= 'base'
      #     end
      #   end
      #
      #   class Derived < Base
      #     def initialize
      #       @config = 'derived'
      #       super
      #     end
      #   end
      #   ----
      #
      #   Without the disjunctive assignment, `Derived` will be unable to override
      #   the value for `@config`.
      #
      # @example
      #   # bad
      #   def initialize
      #     @x ||= 1
      #   end
      #
      #   # good
      #   def initialize
      #     @x = 1
      #   end
      class DisjunctiveAssignmentInConstructor < Base
        extend AutoCorrector

        MSG = 'Unnecessary disjunctive assignment. Use plain assignment.'

        def on_def(node)
          check(node)
        end

        private

        # @param [DefNode] node a constructor definition
        def check(node)
          return unless node.method?(:initialize)

          check_body(node.body)
        end

        def check_body(body)
          return if body.nil?

          case body.type
          when :begin
            check_body_lines(body.child_nodes)
          else
            check_body_lines([body])
          end
        end

        # @param [Array] lines the logical lines of the constructor
        def check_body_lines(lines)
          lines.each do |line|
            case line.type
            when :or_asgn
              check_disjunctive_assignment(line)
            else
              # Once we encounter something other than a disjunctive
              # assignment, we cease our investigation, because we can't be
              # certain that any future disjunctive assignments are offensive.
              # You're off the case, detective!
              break
            end
          end
        end

        # Add an offense if the LHS of the given disjunctive assignment is
        # an instance variable.
        #
        # For now, we only care about assignments to instance variables.
        #
        # @param [Node] node a disjunctive assignment
        def check_disjunctive_assignment(node)
          lhs = node.child_nodes.first
          return unless lhs.ivasgn_type?

          add_offense(node.loc.operator) do |corrector|
            corrector.replace(node.loc.operator, '=')
          end
        end
      end
    end
  end
end
