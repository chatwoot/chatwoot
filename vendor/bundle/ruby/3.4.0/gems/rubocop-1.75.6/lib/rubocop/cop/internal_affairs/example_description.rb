# frozen_string_literal: true

module RuboCop
  module Cop
    module InternalAffairs
      # Checks that RSpec examples that use `expects_offense`
      # or `expects_no_offenses` do not have conflicting
      # descriptions.
      #
      # @example
      #   # bad
      #   it 'does not register an offense' do
      #     expect_offense('...')
      #   end
      #
      #   it 'registers an offense' do
      #     expect_no_offenses('...')
      #   end
      #
      #   # good
      #   it 'registers an offense' do
      #     expect_offense('...')
      #   end
      #
      #   it 'does not register an offense' do
      #     expect_no_offenses('...')
      #   end
      class ExampleDescription < Base
        extend AutoCorrector

        MSG = 'Description does not match use of `%<method_name>s`.'

        RESTRICT_ON_SEND = %i[
          expect_offense
          expect_no_offenses
          expect_correction
          expect_no_corrections
        ].to_set.freeze

        EXPECT_NO_OFFENSES_DESCRIPTION_MAPPING = {
          /\A(adds|registers|reports|finds) (an? )?offense/ => 'does not register an offense',
          /\A(flags|handles|works)\b/ => 'does not register'
        }.freeze

        EXPECT_OFFENSE_DESCRIPTION_MAPPING = {
          /\A(does not|doesn't) (register|find|flag|report)/ => 'registers',
          /\A(does not|doesn't) add (a|an|any )?offense/ => 'registers an offense',
          /\Aregisters no offense/ => 'registers an offense',
          /\A(accepts|register)\b/ => 'registers'
        }.freeze

        EXPECT_NO_CORRECTIONS_DESCRIPTION_MAPPING = {
          /\A(auto[- ]?)?corrects?/ => 'does not correct',
          /\band (auto[- ]?)?corrects/ => 'but does not correct'
        }.freeze

        EXPECT_CORRECTION_DESCRIPTION_MAPPING = {
          /\bbut (does not|doesn't) (auto[- ]?)?correct/ => 'and autocorrects',
          /\b(does not|doesn't) (auto[- ]?)?correct/ => 'autocorrects'
        }.freeze

        EXAMPLE_DESCRIPTION_MAPPING = {
          expect_no_offenses: EXPECT_NO_OFFENSES_DESCRIPTION_MAPPING,
          expect_offense: EXPECT_OFFENSE_DESCRIPTION_MAPPING,
          expect_no_corrections: EXPECT_NO_CORRECTIONS_DESCRIPTION_MAPPING,
          expect_correction: EXPECT_CORRECTION_DESCRIPTION_MAPPING
        }.freeze

        # @!method offense_example(node)
        def_node_matcher :offense_example, <<~PATTERN
          (block
            (send _ {:it :specify :xit :fit} $...)
            _args
            `(send nil? %RESTRICT_ON_SEND ...)
          )
        PATTERN

        def on_send(node)
          parent = node.each_ancestor(:block).first
          return unless parent && (current_description = offense_example(parent)&.first)

          method_name = node.method_name
          message = format(MSG, method_name: method_name)

          description_map = EXAMPLE_DESCRIPTION_MAPPING[method_name]
          check_description(current_description, description_map, message)
        end

        private

        def check_description(current_description, description_map, message)
          description_text = string_contents(current_description)
          return unless (new_description = correct_description(description_text, description_map))

          quote = current_description.dstr_type? ? '"' : "'"

          add_offense(current_description, message: message) do |corrector|
            corrector.replace(current_description, "#{quote}#{new_description}#{quote}")
          end
        end

        def correct_description(current_description, description_map)
          description_map.each do |incorrect_description_pattern, preferred_description|
            if incorrect_description_pattern.match?(current_description)
              return current_description.gsub(incorrect_description_pattern, preferred_description)
            end
          end

          nil
        end

        def string_contents(node)
          node.type?(:str, :dstr) ? node.value : node.source
        end
      end
    end
  end
end
