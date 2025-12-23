# frozen_string_literal: true

module RuboCop
  module Cop
    module Bundler
      # Enforce that Gem version specifications or a commit reference (branch,
      # ref, or tag) are either required or forbidden.
      #
      # @example EnforcedStyle: required (default)
      #  # bad
      #  gem 'rubocop'
      #
      #  # good
      #  gem 'rubocop', '~> 1.12'
      #
      #  # good
      #  gem 'rubocop', '>= 1.10.0'
      #
      #  # good
      #  gem 'rubocop', '>= 1.5.0', '< 1.10.0'
      #
      #  # good
      #  gem 'rubocop', branch: 'feature-branch'
      #
      #  # good
      #  gem 'rubocop', ref: '74b5bfbb2c4b6fd6cdbbc7254bd7084b36e0c85b'
      #
      #  # good
      #  gem 'rubocop', tag: 'v1.17.0'
      #
      # @example EnforcedStyle: forbidden
      #  # good
      #  gem 'rubocop'
      #
      #  # bad
      #  gem 'rubocop', '~> 1.12'
      #
      #  # bad
      #  gem 'rubocop', '>= 1.10.0'
      #
      #  # bad
      #  gem 'rubocop', '>= 1.5.0', '< 1.10.0'
      #
      #  # bad
      #  gem 'rubocop', branch: 'feature-branch'
      #
      #  # bad
      #  gem 'rubocop', ref: '74b5bfbb2c4b6fd6cdbbc7254bd7084b36e0c85b'
      #
      #  # bad
      #  gem 'rubocop', tag: 'v1.17.0'
      #
      class GemVersion < Base
        include ConfigurableEnforcedStyle
        include GemDeclaration

        REQUIRED_MSG = 'Gem version specification is required.'
        FORBIDDEN_MSG = 'Gem version specification is forbidden.'
        RESTRICT_ON_SEND = %i[gem].freeze
        VERSION_SPECIFICATION_REGEX = /^\s*[~<>=]*\s*[0-9.]+/.freeze

        # @!method includes_version_specification?(node)
        def_node_matcher :includes_version_specification?, <<~PATTERN
          (send nil? :gem <(str #version_specification?) ...>)
        PATTERN

        # @!method includes_commit_reference?(node)
        def_node_matcher :includes_commit_reference?, <<~PATTERN
          (send nil? :gem <(hash <(pair (sym {:branch :ref :tag}) (str _)) ...>) ...>)
        PATTERN

        def on_send(node)
          return unless gem_declaration?(node)
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
          allowed_gems.include?(node.first_argument.value)
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
