# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks that memoized helpers names are symbols or strings.
      #
      # @example EnforcedStyle: symbols (default)
      #   # bad
      #   subject('user') { create_user }
      #   let('user_name') { 'Adam' }
      #
      #   # good
      #   subject(:user) { create_user }
      #   let(:user_name) { 'Adam' }
      #
      # @example EnforcedStyle: strings
      #   # bad
      #   subject(:user) { create_user }
      #   let(:user_name) { 'Adam' }
      #
      #   # good
      #   subject('user') { create_user }
      #   let('user_name') { 'Adam' }
      #
      class VariableDefinition < Base
        extend AutoCorrector
        include ConfigurableEnforcedStyle
        include Variable
        include InsideExampleGroup

        MSG = 'Use %<style>s for variable names.'

        def on_send(node)
          return unless inside_example_group?(node)

          variable_definition?(node) do |variable|
            next unless style_offense?(variable)

            add_offense(
              variable,
              message: format(MSG, style: style)
            ) do |corrector|
              corrector.replace(variable, correct_variable(variable))
            end
          end
        end

        private

        def correct_variable(variable)
          case variable.type
          when :dsym
            variable.source[1..]
          when :sym
            variable.value.to_s.inspect
          else
            variable.value.to_sym.inspect
          end
        end

        def style_offense?(variable)
          (style == :symbols && string?(variable)) ||
            (style == :strings && symbol?(variable))
        end

        def string?(node)
          node.str_type?
        end

        def symbol?(node)
          node.type?(:sym, :dsym)
        end
      end
    end
  end
end
