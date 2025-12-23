# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Check that certain constants are fully qualified.
      #
      # This is not enabled by default because it would mark a lot of offenses
      # unnecessarily.
      #
      # Generally, gems should fully qualify all constants to avoid conflicts with
      # the code that uses the gem. Enable this cop without using `Only`/`Ignore`
      #
      # Large projects will over time end up with one or two constant names that
      # are problematic because of a conflict with a library or just internally
      # using the same name a namespace and a class. To avoid too many unnecessary
      # offenses, Enable this cop with `Only: [The, Constant, Names, Causing, Issues]`
      #
      # NOTE: `Style/RedundantConstantBase` cop is disabled if this cop is enabled to prevent
      # conflicting rules. Because it respects user configurations that want to enable
      # this cop which is disabled by default.
      #
      # @example
      #   # By default checks every constant
      #
      #   # bad
      #   User
      #
      #   # bad
      #   User::Login
      #
      #   # good
      #   ::User
      #
      #   # good
      #   ::User::Login
      #
      # @example Only: ['Login']
      #   # Restrict this cop to only being concerned about certain constants
      #
      #   # bad
      #   Login
      #
      #   # good
      #   ::Login
      #
      #   # good
      #   User::Login
      #
      # @example Ignore: ['Login']
      #   # Restrict this cop not being concerned about certain constants
      #
      #   # bad
      #   User
      #
      #   # good
      #   ::User::Login
      #
      #   # good
      #   Login
      #
      class ConstantResolution < Base
        MSG = 'Fully qualify this constant to avoid possibly ambiguous resolution.'

        # @!method unqualified_const?(node)
        def_node_matcher :unqualified_const?, <<~PATTERN
          (const nil? #const_name?)
        PATTERN

        def on_const(node)
          return if !unqualified_const?(node) || node.parent&.defined_module || node.loc.nil?

          add_offense(node)
        end

        private

        def const_name?(name)
          name = name.to_s
          (allowed_names.empty? || allowed_names.include?(name)) && !ignored_names.include?(name)
        end

        def allowed_names
          cop_config['Only']
        end

        def ignored_names
          cop_config['Ignore']
        end
      end
    end
  end
end
