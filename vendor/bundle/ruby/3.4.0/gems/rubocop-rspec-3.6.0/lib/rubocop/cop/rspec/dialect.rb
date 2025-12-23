# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Enforces custom RSpec dialects.
      #
      # A dialect can be based on the following RSpec methods:
      #
      # - describe, context, feature, example_group
      # - xdescribe, xcontext, xfeature
      # - fdescribe, fcontext, ffeature
      # - shared_examples, shared_examples_for, shared_context
      # - it, specify, example, scenario, its
      # - fit, fspecify, fexample, fscenario, focus
      # - xit, xspecify, xexample, xscenario, skip
      # - pending
      # - prepend_before, before, append_before,
      # - around
      # - prepend_after, after, append_after
      # - let, let!
      # - subject, subject!
      # - expect, is_expected, expect_any_instance_of
      #
      # By default all of the RSpec methods and aliases are allowed. By setting
      # a config like:
      #
      #   RSpec/Dialect:
      #     PreferredMethods:
      #       context: describe
      #
      # If you were previously using the `RSpec/Capybara/FeatureMethods` cop and
      # want to keep disabling all Capybara-specific methods that have the same
      # native RSpec method (e.g. are just aliases), use the following config:
      #
      #   RSpec/Dialect:
      #     PreferredMethods:
      #       background: :before
      #       scenario:   :it
      #       xscenario:  :xit
      #       given:      :let
      #       given!:     :let!
      #       feature:    :describe
      #
      # You can expect the following behavior:
      #
      # @example
      #   # bad
      #   context 'display name presence' do
      #     # ...
      #   end
      #
      #   # good
      #   describe 'display name presence' do
      #     # ...
      #   end
      #
      class Dialect < Base
        extend AutoCorrector
        include MethodPreference

        MSG = 'Prefer `%<prefer>s` over `%<current>s`.'

        # @!method rspec_method?(node)
        def_node_matcher :rspec_method?, '(send #rspec? #ALL.all ...)'

        def on_send(node)
          return unless rspec_method?(node)
          return unless preferred_methods[node.method_name]

          msg = format(MSG, prefer: preferred_method(node.method_name),
                            current: node.method_name)

          add_offense(node, message: msg) do |corrector|
            current = node.loc.selector
            preferred = preferred_method(current.source)

            corrector.replace(current, preferred)
          end
        end
      end
    end
  end
end
