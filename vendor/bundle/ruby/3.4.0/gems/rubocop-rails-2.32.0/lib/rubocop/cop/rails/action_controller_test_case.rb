# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Using `ActionController::TestCase` is discouraged and should be replaced by
      # `ActionDispatch::IntegrationTest`. Controller tests are too close to the
      # internals of a controller whereas integration tests mimic the browser/user.
      #
      # @safety
      #   This cop's autocorrection is unsafe because the API of each test case class is different.
      #   Make sure to update each test of your controller test cases after changing the superclass.
      #
      # @example
      #   # bad
      #   class MyControllerTest < ActionController::TestCase
      #   end
      #
      #   # good
      #   class MyControllerTest < ActionDispatch::IntegrationTest
      #   end
      #
      class ActionControllerTestCase < Base
        extend AutoCorrector
        extend TargetRailsVersion

        MSG = 'Use `ActionDispatch::IntegrationTest` instead.'

        minimum_target_rails_version 5.0

        def_node_matcher :action_controller_test_case?, <<~PATTERN
          (class
            (const _ _)
            (const (const {nil? cbase} :ActionController) :TestCase) _)
        PATTERN

        def on_class(node)
          return unless action_controller_test_case?(node)

          add_offense(node.parent_class) do |corrector|
            corrector.replace(node.parent_class, 'ActionDispatch::IntegrationTest')
          end
        end
      end
    end
  end
end
