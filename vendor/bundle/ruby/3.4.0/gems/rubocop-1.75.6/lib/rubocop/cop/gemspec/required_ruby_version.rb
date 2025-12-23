# frozen_string_literal: true

module RuboCop
  module Cop
    module Gemspec
      # Checks that `required_ruby_version` in a gemspec file is set to a valid
      # value (non-blank) and matches `TargetRubyVersion` as set in RuboCop's
      # configuration for the gem.
      #
      # This ensures that RuboCop is using the same Ruby version as the gem.
      #
      # @example
      #   # When `TargetRubyVersion` of .rubocop.yml is `2.5`.
      #
      #   # bad
      #   Gem::Specification.new do |spec|
      #     # no `required_ruby_version` specified
      #   end
      #
      #   # bad
      #   Gem::Specification.new do |spec|
      #     spec.required_ruby_version = '>= 2.4.0'
      #   end
      #
      #   # bad
      #   Gem::Specification.new do |spec|
      #     spec.required_ruby_version = '>= 2.6.0'
      #   end
      #
      #   # bad
      #   Gem::Specification.new do |spec|
      #     spec.required_ruby_version = ''
      #   end
      #
      #   # good
      #   Gem::Specification.new do |spec|
      #     spec.required_ruby_version = '>= 2.5.0'
      #   end
      #
      #   # good
      #   Gem::Specification.new do |spec|
      #     spec.required_ruby_version = '>= 2.5'
      #   end
      #
      #   # accepted but not recommended
      #   Gem::Specification.new do |spec|
      #     spec.required_ruby_version = ['>= 2.5.0', '< 2.7.0']
      #   end
      #
      #   # accepted but not recommended, since
      #   # Ruby does not really follow semantic versioning
      #   Gem::Specification.new do |spec|
      #     spec.required_ruby_version = '~> 2.5'
      #   end
      class RequiredRubyVersion < Base
        RESTRICT_ON_SEND = %i[required_ruby_version=].freeze
        NOT_EQUAL_MSG = '`required_ruby_version` and `TargetRubyVersion` ' \
                        '(%<target_ruby_version>s, which may be specified in ' \
                        '.rubocop.yml) should be equal.'
        MISSING_MSG = '`required_ruby_version` should be specified.'

        # @!method required_ruby_version?(node)
        def_node_search :required_ruby_version?, <<~PATTERN
          (send _ :required_ruby_version= _)
        PATTERN

        # @!method defined_ruby_version(node)
        def_node_matcher :defined_ruby_version, <<~PATTERN
          {
            $(str _)
            $(array (str _) (str _))
            (send (const (const nil? :Gem) :Requirement) :new $str+)
          }
        PATTERN

        def on_new_investigation
          return if processed_source.ast && required_ruby_version?(processed_source.ast)

          add_global_offense(MISSING_MSG)
        end

        def on_send(node)
          version_def = node.first_argument
          return if dynamic_version?(version_def)

          ruby_version = extract_ruby_version(defined_ruby_version(version_def))
          return if ruby_version == target_ruby_version.to_s

          add_offense(version_def, message: not_equal_message(ruby_version, target_ruby_version))
        end

        private

        def dynamic_version?(node)
          (node.send_type? && !node.receiver) ||
            node.variable? ||
            node.each_descendant(:send, *RuboCop::AST::Node::VARIABLES).any?
        end

        def extract_ruby_version(required_ruby_version)
          return unless required_ruby_version

          if required_ruby_version.is_a?(Array)
            required_ruby_version = required_ruby_version.detect do |v|
              /[>=]/.match?(v.str_content)
            end
          elsif required_ruby_version.array_type?
            required_ruby_version = required_ruby_version.children.detect do |v|
              /[>=]/.match?(v.str_content)
            end
          end

          return unless required_ruby_version

          required_ruby_version.str_content.scan(/\d/).first(2).join('.')
        end

        def not_equal_message(required_ruby_version, target_ruby_version)
          format(
            NOT_EQUAL_MSG,
            required_ruby_version: required_ruby_version,
            gemspec_filename: File.basename(processed_source.file_path),
            target_ruby_version: target_ruby_version
          )
        end
      end
    end
  end
end
