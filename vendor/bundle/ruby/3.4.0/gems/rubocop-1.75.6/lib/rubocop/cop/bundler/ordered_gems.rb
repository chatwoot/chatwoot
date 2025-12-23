# frozen_string_literal: true

module RuboCop
  module Cop
    module Bundler
      # Gems should be alphabetically sorted within groups.
      #
      # @example
      #   # bad
      #   gem 'rubocop'
      #   gem 'rspec'
      #
      #   # good
      #   gem 'rspec'
      #   gem 'rubocop'
      #
      #   # good
      #   gem 'rubocop'
      #
      #   gem 'rspec'
      #
      # @example TreatCommentsAsGroupSeparators: true (default)
      #   # good
      #   # For code quality
      #   gem 'rubocop'
      #   # For tests
      #   gem 'rspec'
      #
      # @example TreatCommentsAsGroupSeparators: false
      #   # bad
      #   # For code quality
      #   gem 'rubocop'
      #   # For tests
      #   gem 'rspec'
      class OrderedGems < Base
        extend AutoCorrector
        include OrderedGemNode

        MSG = 'Gems should be sorted in an alphabetical order within their ' \
              'section of the Gemfile. ' \
              'Gem `%<previous>s` should appear before `%<current>s`.'

        def on_new_investigation
          return if processed_source.blank?

          gem_declarations(processed_source.ast)
            .each_cons(2) do |previous, current|
            next unless consecutive_lines(previous, current)
            next unless case_insensitive_out_of_order?(gem_name(current), gem_name(previous))

            register_offense(previous, current)
          end
        end

        private

        def previous_declaration(node)
          declarations = gem_declarations(processed_source.ast)
          node_index = declarations.map(&:location).find_index(node.location)
          declarations.to_a[node_index - 1]
        end

        # @!method gem_declarations(node)
        def_node_search :gem_declarations, <<~PATTERN
          (:send nil? :gem str ...)
        PATTERN
      end
    end
  end
end
