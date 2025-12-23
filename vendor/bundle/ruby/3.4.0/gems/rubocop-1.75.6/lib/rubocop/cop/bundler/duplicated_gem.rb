# frozen_string_literal: true

module RuboCop
  module Cop
    module Bundler
      # A Gem's requirements should be listed only once in a Gemfile.
      #
      # @example
      #   # bad
      #   gem 'rubocop'
      #   gem 'rubocop'
      #
      #   # bad
      #   group :development do
      #     gem 'rubocop'
      #   end
      #
      #   group :test do
      #     gem 'rubocop'
      #   end
      #
      #   # good
      #   group :development, :test do
      #     gem 'rubocop'
      #   end
      #
      #   # good
      #   gem 'rubocop', groups: [:development, :test]
      #
      #   # good - conditional declaration
      #   if Dir.exist?(local)
      #     gem 'rubocop', path: local
      #   elsif ENV['RUBOCOP_VERSION'] == 'master'
      #     gem 'rubocop', git: 'https://github.com/rubocop/rubocop.git'
      #   else
      #     gem 'rubocop', '~> 0.90.0'
      #   end
      #
      class DuplicatedGem < Base
        include RangeHelp

        MSG = 'Gem `%<gem_name>s` requirements already given on line ' \
              '%<line_of_first_occurrence>d of the Gemfile.'

        def on_new_investigation
          return if processed_source.blank?

          duplicated_gem_nodes.each do |nodes|
            nodes[1..].each do |node|
              register_offense(node, node.first_argument.to_a.first, nodes.first.first_line)
            end
          end
        end

        private

        # @!method gem_declarations(node)
        def_node_search :gem_declarations, '(send nil? :gem str ...)'

        def duplicated_gem_nodes
          gem_declarations(processed_source.ast)
            .group_by(&:first_argument)
            .values
            .select { |nodes| nodes.size > 1 && !conditional_declaration?(nodes) }
        end

        def conditional_declaration?(nodes)
          parent = nodes[0].each_ancestor.find { |ancestor| !ancestor.begin_type? }
          return false unless parent&.type?(:if, :when)

          root_conditional_node = parent.if_type? ? parent : parent.parent
          nodes.all? { |node| within_conditional?(node, root_conditional_node) }
        end

        def within_conditional?(node, conditional_node)
          conditional_node.branches.compact.any? do |branch|
            branch == node || branch.child_nodes.include?(node)
          end
        end

        def register_offense(node, gem_name, line_of_first_occurrence)
          line_range = node.loc.column...node.loc.last_column
          offense_location = source_range(processed_source.buffer, node.first_line, line_range)
          message = format(
            MSG,
            gem_name: gem_name,
            line_of_first_occurrence: line_of_first_occurrence
          )
          add_offense(offense_location, message: message)
        end
      end
    end
  end
end
