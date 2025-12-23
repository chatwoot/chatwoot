# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for duplicate ``require``s and ``require_relative``s.
      #
      # @safety
      #   This cop's autocorrection is unsafe because it may break the dependency order
      #   of `require`.
      #
      # @example
      #   # bad
      #   require 'foo'
      #   require 'bar'
      #   require 'foo'
      #
      #   # good
      #   require 'foo'
      #   require 'bar'
      #
      #   # good
      #   require 'foo'
      #   require_relative 'foo'
      #
      class DuplicateRequire < Base
        include RangeHelp
        extend AutoCorrector

        MSG = 'Duplicate `%<method>s` detected.'
        REQUIRE_METHODS = Set.new(%i[require require_relative]).freeze
        RESTRICT_ON_SEND = REQUIRE_METHODS

        # @!method require_call?(node)
        def_node_matcher :require_call?, <<~PATTERN
          (send {nil? (const _ :Kernel)} %REQUIRE_METHODS _)
        PATTERN

        def on_new_investigation
          # Holds the known required files for a given parent node (used as key)
          @required = Hash.new { |h, k| h[k] = Set.new }.compare_by_identity
          super
        end

        def on_send(node)
          return unless require_call?(node)
          return if @required[node.parent].add?("#{node.method_name}#{node.first_argument}")

          add_offense(node, message: format(MSG, method: node.method_name)) do |corrector|
            corrector.remove(range_by_whole_lines(node.source_range, include_final_newline: true))
          end
        end
      end
    end
  end
end
