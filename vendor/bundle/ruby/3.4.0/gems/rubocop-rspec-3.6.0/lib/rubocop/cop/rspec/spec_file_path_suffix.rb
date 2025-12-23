# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks that spec file paths suffix are consistent and well-formed.
      #
      # @example
      #   # bad
      #   my_class/foo_specorb.rb   # describe MyClass
      #   spec/models/user.rb       # describe User
      #   spec/models/user_specxrb  # describe User
      #
      #   # good
      #   my_class_spec.rb          # describe MyClass
      #
      #   # good - shared examples are allowed
      #   spec/models/user.rb       # shared_examples_for 'foo'
      #
      class SpecFilePathSuffix < Base
        include TopLevelGroup
        include FileHelp

        MSG = 'Spec path should end with `_spec.rb`.'

        def on_top_level_example_group(node)
          example_group?(node) do
            add_global_offense(MSG) unless correct_path?
          end
        end

        private

        def correct_path?
          expanded_file_path.end_with?('_spec.rb')
        end
      end
    end
  end
end
