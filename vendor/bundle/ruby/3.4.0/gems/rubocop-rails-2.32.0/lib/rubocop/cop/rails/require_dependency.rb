# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Checks for the usage of `require_dependency`.
      #
      # `require_dependency` is an obsolete method for Rails applications running in Zeitwerk mode.
      # In Zeitwerk mode, the semantics should match Ruby's and no need to be defensive with load order,
      # just refer to classes and modules normally.
      # If the constant name is dynamic, camelize if needed, and constantize.
      #
      # Applications running in Zeitwerk mode should not use `require_dependency`.
      #
      # NOTE: This cop is disabled by default. Please enable it if you are using Zeitwerk mode.
      #
      # @example
      #   # bad
      #   require_dependency 'some_lib'
      class RequireDependency < Base
        extend TargetRailsVersion

        minimum_target_rails_version 6.0

        MSG = 'Do not use `require_dependency` with Zeitwerk mode.'
        RESTRICT_ON_SEND = %i[require_dependency].freeze

        def_node_matcher :require_dependency_call?, <<~PATTERN
          (send {nil? (const {nil? cbase} :Kernel)} :require_dependency _)
        PATTERN

        def on_send(node)
          require_dependency_call?(node) { add_offense(node) }
        end
      end
    end
  end
end
