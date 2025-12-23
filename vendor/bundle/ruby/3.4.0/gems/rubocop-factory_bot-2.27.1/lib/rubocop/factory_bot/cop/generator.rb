# frozen_string_literal: true

module RuboCop
  module FactoryBot
    module Cop
      # Source and spec generator for new cops
      #
      # This generator will take a cop name and generate a source file
      # and spec file when given a valid qualified cop name.
      # @api private
      class Generator < RuboCop::Cop::Generator
        def todo
          <<~TODO
            Do 4 steps:
              1. Modify the description of #{badge} in config/default.yml
              2. Implement your new cop in the generated file!
              3. Add an entry about new cop to CHANGELOG.md
              4. Commit your new cop with a message such as
                 e.g. "Add new `#{badge}` cop"
          TODO
        end
      end
    end
  end
end
