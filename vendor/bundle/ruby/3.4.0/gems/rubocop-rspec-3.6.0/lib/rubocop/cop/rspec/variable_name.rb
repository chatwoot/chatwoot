# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks that memoized helper names use the configured style.
      #
      # Variables can be excluded from checking using the `AllowedPatterns`
      # option.
      #
      # @example EnforcedStyle: snake_case (default)
      #   # bad
      #   subject(:userName1) { 'Adam' }
      #   let(:userName2) { 'Adam' }
      #
      #   # good
      #   subject(:user_name_1) { 'Adam' }
      #   let(:user_name_2) { 'Adam' }
      #
      # @example EnforcedStyle: camelCase
      #   # bad
      #   subject(:user_name_1) { 'Adam' }
      #   let(:user_name_2) { 'Adam' }
      #
      #   # good
      #   subject(:userName1) { 'Adam' }
      #   let(:userName2) { 'Adam' }
      #
      # @example AllowedPatterns configuration
      #   # rubocop.yml
      #   # RSpec/VariableName:
      #   #   EnforcedStyle: snake_case
      #   #   AllowedPatterns:
      #   #     - ^userFood
      #
      # @example
      #   # okay because it matches the `^userFood` regex in `AllowedPatterns`
      #   subject(:userFood_1) { 'spaghetti' }
      #   let(:userFood_2) { 'fettuccine' }
      #
      class VariableName < Base
        include ConfigurableNaming
        include AllowedPattern
        include Variable
        include InsideExampleGroup

        MSG = 'Use %<style>s for variable names.'

        def on_send(node)
          return unless inside_example_group?(node)

          variable_definition?(node) do |variable|
            return if variable.type?(:dstr, :dsym)
            return if matches_allowed_pattern?(variable.value)

            check_name(node, variable.value, variable.source_range)
          end
        end

        private

        def message(style)
          format(MSG, style: style)
        end
      end
    end
  end
end
