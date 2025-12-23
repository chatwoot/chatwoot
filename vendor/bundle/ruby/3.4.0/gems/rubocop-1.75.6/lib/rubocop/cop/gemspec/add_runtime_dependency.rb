# frozen_string_literal: true

module RuboCop
  module Cop
    module Gemspec
      # Prefer `add_dependency` over `add_runtime_dependency` as the latter is
      # considered soft-deprecated.
      #
      # @example
      #
      #   # bad
      #   Gem::Specification.new do |spec|
      #     spec.add_runtime_dependency('rubocop')
      #   end
      #
      #   # good
      #   Gem::Specification.new do |spec|
      #     spec.add_dependency('rubocop')
      #   end
      #
      class AddRuntimeDependency < Base
        extend AutoCorrector

        MSG = 'Use `add_dependency` instead of `add_runtime_dependency`.'

        RESTRICT_ON_SEND = %i[add_runtime_dependency].freeze

        def on_send(node)
          return if !node.receiver || node.arguments.empty?

          add_offense(node.loc.selector) do |corrector|
            corrector.replace(node.loc.selector, 'add_dependency')
          end
        end
      end
    end
  end
end
