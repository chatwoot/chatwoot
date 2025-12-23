# frozen_string_literal: true

module RuboCop
  module Cop
    module FactoryBot
      # Handles `ExplicitOnly` configuration parameters.
      module ConfigurableExplicitOnly
        include RuboCop::FactoryBot::Language

        def factory_call?(node)
          return factory_bot?(node) if explicit_only?

          factory_bot?(node) || node.nil?
        end

        def explicit_only?
          cop_config['ExplicitOnly']
        end
      end
    end
  end
end
