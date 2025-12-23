# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Helps check offenses with variable definitions
      module Variable
        extend RuboCop::NodePattern::Macros

        Subjects = RuboCop::RSpec::Language::Subjects
        Helpers = RuboCop::RSpec::Language::Helpers

        # @!method variable_definition?(node)
        def_node_matcher :variable_definition?, <<~PATTERN
          (send nil? {#Subjects.all #Helpers.all}
            $({sym str dsym dstr} ...) ...)
        PATTERN
      end
    end
  end
end
