# frozen_string_literal: true

module RuboCop
  module Cop
    module Naming
      # Makes sure that rescued exceptions variables are named as
      # expected.
      #
      # The `PreferredName` config option takes a `String`. It represents
      # the required name of the variable. Its default is `e`.
      #
      # NOTE: This cop does not consider nested rescues because it cannot
      # guarantee that the variable from the outer rescue is not used within
      # the inner rescue (in which case, changing the inner variable would
      # shadow the outer variable).
      #
      # @example PreferredName: e (default)
      #   # bad
      #   begin
      #     # do something
      #   rescue MyException => exception
      #     # do something
      #   end
      #
      #   # good
      #   begin
      #     # do something
      #   rescue MyException => e
      #     # do something
      #   end
      #
      #   # good
      #   begin
      #     # do something
      #   rescue MyException => _e
      #     # do something
      #   end
      #
      # @example PreferredName: exception
      #   # bad
      #   begin
      #     # do something
      #   rescue MyException => e
      #     # do something
      #   end
      #
      #   # good
      #   begin
      #     # do something
      #   rescue MyException => exception
      #     # do something
      #   end
      #
      #   # good
      #   begin
      #     # do something
      #   rescue MyException => _exception
      #     # do something
      #   end
      #
      class RescuedExceptionsVariableName < Base
        extend AutoCorrector

        MSG = 'Use `%<preferred>s` instead of `%<bad>s`.'

        def on_resbody(node)
          offending_name = variable_name(node)
          return unless offending_name

          # Handle nested rescues by only requiring the outer one to use the
          # configured variable name, so that nested rescues don't use the same
          # variable.
          return if node.each_ancestor(:resbody).any?

          preferred_name = preferred_name(offending_name)
          return if preferred_name.to_sym == offending_name

          # check variable shadowing for exception variable
          return if shadowed_variable_name?(node)

          range = offense_range(node)
          message = message(node)

          add_offense(range, message: message) do |corrector|
            autocorrect(corrector, node, range, offending_name, preferred_name)
          end
        end

        private

        def offense_range(resbody)
          variable = resbody.exception_variable
          variable.source_range
        end

        def autocorrect(corrector, node, range, offending_name, preferred_name)
          corrector.replace(range, preferred_name)
          correct_node(corrector, node.body, offending_name, preferred_name)
          return unless (kwbegin_node = node.parent.each_ancestor(:kwbegin).first)

          kwbegin_node.right_siblings.each do |child_node|
            correct_node(corrector, child_node, offending_name, preferred_name)
          end
        end

        def variable_name_matches?(node, name)
          if node.masgn_type?
            node.each_descendant(:lvasgn).any? do |lvasgn_node|
              variable_name_matches?(lvasgn_node, name)
            end
          else
            node.name == name
          end
        end

        # rubocop:disable Metrics/MethodLength
        def correct_node(corrector, node, offending_name, preferred_name)
          return unless node

          node.each_node(:lvar, :lvasgn, :masgn) do |child_node|
            next unless variable_name_matches?(child_node, offending_name)

            if child_node.lvar_type?
              parent_node = child_node.parent
              if parent_node.respond_to?(:value_omission?) && parent_node.value_omission?
                corrector.insert_after(parent_node.loc.operator, " #{preferred_name}")
              else
                corrector.replace(child_node, preferred_name)
              end
            end

            if child_node.type?(:masgn, :lvasgn)
              correct_reassignment(corrector, child_node, offending_name, preferred_name)
              break
            end
          end
        end
        # rubocop:enable Metrics/MethodLength

        # If the exception variable is reassigned, that assignment needs to be corrected.
        # Further `lvar` nodes will not be corrected though since they now refer to a
        # different variable.
        def correct_reassignment(corrector, node, offending_name, preferred_name)
          correct_node(corrector, node.rhs, offending_name, preferred_name)
        end

        def preferred_name(variable_name)
          preferred_name = cop_config.fetch('PreferredName', 'e')
          if variable_name.to_s.start_with?('_')
            "_#{preferred_name}"
          else
            preferred_name
          end
        end

        def variable_name(node)
          node.exception_variable.name if node.exception_variable.respond_to?(:name)
        end

        def message(node)
          offending_name = variable_name(node)
          preferred_name = preferred_name(offending_name)
          format(MSG, preferred: preferred_name, bad: offending_name)
        end

        def shadowed_variable_name?(node)
          node.each_descendant(:lvar).any? { |n| n.children.first.to_s == preferred_name(n) }
        end
      end
    end
  end
end
