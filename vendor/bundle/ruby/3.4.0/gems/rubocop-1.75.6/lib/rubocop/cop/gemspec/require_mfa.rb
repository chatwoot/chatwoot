# frozen_string_literal: true

module RuboCop
  module Cop
    module Gemspec
      # Requires a gemspec to have `rubygems_mfa_required` metadata set.
      #
      # This setting tells RubyGems that MFA (Multi-Factor Authentication) is
      # required for accounts to be able perform privileged operations, such as
      # (see RubyGems' documentation for the full list of privileged
      # operations):
      #
      # * `gem push`
      # * `gem yank`
      # * `gem owner --add/remove`
      # * adding or removing owners using gem ownership page
      #
      # This helps make your gem more secure, as users can be more
      # confident that gem updates were pushed by maintainers.
      #
      # @example
      #   # bad
      #   Gem::Specification.new do |spec|
      #     # no `rubygems_mfa_required` metadata specified
      #   end
      #
      #   # good
      #   Gem::Specification.new do |spec|
      #     spec.metadata = {
      #       'rubygems_mfa_required' => 'true'
      #     }
      #   end
      #
      #   # good
      #   Gem::Specification.new do |spec|
      #     spec.metadata['rubygems_mfa_required'] = 'true'
      #   end
      #
      #   # bad
      #   Gem::Specification.new do |spec|
      #     spec.metadata = {
      #       'rubygems_mfa_required' => 'false'
      #     }
      #   end
      #
      #   # good
      #   Gem::Specification.new do |spec|
      #     spec.metadata = {
      #       'rubygems_mfa_required' => 'true'
      #     }
      #   end
      #
      #   # bad
      #   Gem::Specification.new do |spec|
      #     spec.metadata['rubygems_mfa_required'] = 'false'
      #   end
      #
      #   # good
      #   Gem::Specification.new do |spec|
      #     spec.metadata['rubygems_mfa_required'] = 'true'
      #   end
      #
      class RequireMFA < Base
        include GemspecHelp
        extend AutoCorrector

        MSG = "`metadata['rubygems_mfa_required']` must be set to `'true'`."

        # @!method metadata(node)
        def_node_matcher :metadata, <<~PATTERN
          `{
            (send _ :metadata= $_)
            (send (send _ :metadata) :[]= (str "rubygems_mfa_required") $_)
          }
        PATTERN

        # @!method rubygems_mfa_required(node)
        def_node_search :rubygems_mfa_required, <<~PATTERN
          (pair (str "rubygems_mfa_required") $_)
        PATTERN

        # @!method true_string?(node)
        def_node_matcher :true_string?, <<~PATTERN
          (str "true")
        PATTERN

        def on_block(node) # rubocop:disable Metrics/MethodLength, InternalAffairs/NumblockHandler
          gem_specification(node) do |block_var|
            metadata_value = metadata(node)
            mfa_value = mfa_value(metadata_value)

            if mfa_value
              unless true_string?(mfa_value)
                add_offense(mfa_value) do |corrector|
                  change_value(corrector, mfa_value)
                end
              end
            else
              add_offense(node) do |corrector|
                autocorrect(corrector, node, block_var, metadata_value)
              end
            end
          end
        end

        private

        def mfa_value(metadata_value)
          return unless metadata_value
          return metadata_value if metadata_value.str_type?

          rubygems_mfa_required(metadata_value).first
        end

        def autocorrect(corrector, node, block_var, metadata)
          if metadata
            return unless metadata.hash_type?

            correct_metadata(corrector, metadata)
          else
            insert_mfa_required(corrector, node, block_var)
          end
        end

        def correct_metadata(corrector, metadata)
          if metadata.pairs.any?
            corrector.insert_after(metadata.pairs.last, ",\n'rubygems_mfa_required' => 'true'")
          else
            corrector.insert_before(metadata.loc.end, "'rubygems_mfa_required' => 'true'")
          end
        end

        def insert_mfa_required(corrector, node, block_var)
          corrector.insert_before(node.loc.end, <<~RUBY)
            #{block_var}.metadata['rubygems_mfa_required'] = 'true'
          RUBY
        end

        def change_value(corrector, value)
          corrector.replace(value, "'true'")
        end
      end
    end
  end
end
