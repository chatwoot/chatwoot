# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Check for expectations where `be` is used without argument.
      #
      # The `be` matcher is too generic, as it pass on everything that is not
      # nil or false. If that is the exact intend, use `be_truthy`. In all other
      # cases it's better to specify what exactly is the expected value.
      #
      # @example
      #   # bad
      #   expect(foo).to be
      #
      #   # good
      #   expect(foo).to be_truthy
      #   expect(foo).to be 1.0
      #   expect(foo).to be(true)
      #
      class Be < Base
        MSG = "Don't use `be` without an argument."

        RESTRICT_ON_SEND = Runners.all

        # @!method be_without_args(node)
        def_node_matcher :be_without_args, <<~PATTERN
          (send _ #Runners.all $(send nil? :be))
        PATTERN

        def on_send(node)
          be_without_args(node) do |matcher|
            add_offense(matcher.loc.selector)
          end
        end
      end
    end
  end
end
