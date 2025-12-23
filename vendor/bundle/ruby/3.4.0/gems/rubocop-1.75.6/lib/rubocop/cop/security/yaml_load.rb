# frozen_string_literal: true

module RuboCop
  module Cop
    module Security
      # Checks for the use of YAML class methods which have
      # potential security issues leading to remote code execution when
      # loading from an untrusted source.
      #
      # NOTE: Ruby 3.1+ (Psych 4) uses `Psych.load` as `Psych.safe_load` by default.
      #
      # @safety
      #   The behavior of the code might change depending on what was
      #   in the YAML payload, since `YAML.safe_load` is more restrictive.
      #
      # @example
      #   # bad
      #   YAML.load("--- !ruby/object:Foo {}") # Psych 3 is unsafe by default
      #
      #   # good
      #   YAML.safe_load("--- !ruby/object:Foo {}", [Foo])                    # Ruby 2.5  (Psych 3)
      #   YAML.safe_load("--- !ruby/object:Foo {}", permitted_classes: [Foo]) # Ruby 3.0- (Psych 3)
      #   YAML.load("--- !ruby/object:Foo {}", permitted_classes: [Foo])      # Ruby 3.1+ (Psych 4)
      #   YAML.dump(foo)
      #
      class YAMLLoad < Base
        extend AutoCorrector
        extend TargetRubyVersion

        MSG = 'Prefer using `YAML.safe_load` over `YAML.load`.'
        RESTRICT_ON_SEND = %i[load].freeze

        maximum_target_ruby_version 3.0

        # @!method yaml_load(node)
        def_node_matcher :yaml_load, <<~PATTERN
          (send (const {nil? cbase} :YAML) :load ...)
        PATTERN

        def on_send(node)
          yaml_load(node) do
            add_offense(node.loc.selector) do |corrector|
              corrector.replace(node.loc.selector, 'safe_load')
            end
          end
        end
      end
    end
  end
end
