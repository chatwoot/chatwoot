# frozen_string_literal: true

module RuboCop
  module Cop
    module Gemspec
      # Enforce that gem dependency version specifications or a commit reference (branch,
      # ref, or tag) are either required or forbidden.
      #
      # @example EnforcedStyle: required (default)
      #
      #   # bad
      #   Gem::Specification.new do |spec|
      #     spec.add_dependency 'parser'
      #   end
      #
      #   # bad
      #   Gem::Specification.new do |spec|
      #     spec.add_development_dependency 'parser'
      #   end
      #
      #   # good
      #   Gem::Specification.new do |spec|
      #     spec.add_dependency 'parser', '>= 2.3.3.1', '< 3.0'
      #   end
      #
      #   # good
      #   Gem::Specification.new do |spec|
      #     spec.add_development_dependency 'parser', '>= 2.3.3.1', '< 3.0'
      #   end
      #
      # @example EnforcedStyle: forbidden
      #
      #   # bad
      #   Gem::Specification.new do |spec|
      #     spec.add_dependency 'parser', '>= 2.3.3.1', '< 3.0'
      #   end
      #
      #   # bad
      #   Gem::Specification.new do |spec|
      #     spec.add_development_dependency 'parser', '>= 2.3.3.1', '< 3.0'
      #   end
      #
      #   # good
      #   Gem::Specification.new do |spec|
      #     spec.add_dependency 'parser'
      #   end
      #
      #   # good
      #   Gem::Specification.new do |spec|
      #     spec.add_development_dependency 'parser'
      #   end
      #
      class DependencyVersion < Base
        include ConfigurableEnforcedStyle
        include GemspecHelp

        REQUIRED_MSG = 'Dependency version specification is required.'
        FORBIDDEN_MSG = 'Dependency version specification is forbidden.'
        VERSION_SPECIFICATION_REGEX = /^\s*[~<>=]*\s*[0-9.]+/.freeze

        ADD_DEPENDENCY_METHODS = %i[
          add_dependency add_runtime_dependency add_development_dependency
        ].freeze
        RESTRICT_ON_SEND = ADD_DEPENDENCY_METHODS

        # @!method add_dependency_method_declaration?(node)
        def_node_matcher :add_dependency_method_declaration?, <<~PATTERN
          (send
            (lvar #match_block_variable_name?) #add_dependency_method? ...)
        PATTERN

        # @!method includes_version_specification?(node)
        def_node_matcher :includes_version_specification?, <<~PATTERN
          (send _ #add_dependency_method? <(str #version_specification?) ...>)
        PATTERN

        # @!method includes_commit_reference?(node)
        def_node_matcher :includes_commit_reference?, <<~PATTERN
          (send _ #add_dependency_method? <(hash <(pair (sym {:branch :ref :tag}) (str _)) ...>) ...>)
        PATTERN

        def on_send(node)
          return unless add_dependency_method_declaration?(node)
          return if allowed_gem?(node)

          if offense?(node)
            add_offense(node)
            opposite_style_detected
          else
            correct_style_detected
          end
        end

        private

        def allowed_gem?(node)
          allowed_gems.include?(node.first_argument.str_content)
        end

        def allowed_gems
          Array(cop_config['AllowedGems'])
        end

        def message(_range)
          if required_style?
            REQUIRED_MSG
          elsif forbidden_style?
            FORBIDDEN_MSG
          end
        end

        def match_block_variable_name?(receiver_name)
          gem_specification(processed_source.ast) do |block_variable_name|
            return block_variable_name == receiver_name
          end
        end

        def add_dependency_method?(method_name)
          ADD_DEPENDENCY_METHODS.include?(method_name)
        end

        def offense?(node)
          required_offense?(node) || forbidden_offense?(node)
        end

        def required_offense?(node)
          return false unless required_style?

          !includes_version_specification?(node) && !includes_commit_reference?(node)
        end

        def forbidden_offense?(node)
          return false unless forbidden_style?

          includes_version_specification?(node) || includes_commit_reference?(node)
        end

        def forbidden_style?
          style == :forbidden
        end

        def required_style?
          style == :required
        end

        def version_specification?(expression)
          expression.match?(VERSION_SPECIFICATION_REGEX)
        end
      end
    end
  end
end
