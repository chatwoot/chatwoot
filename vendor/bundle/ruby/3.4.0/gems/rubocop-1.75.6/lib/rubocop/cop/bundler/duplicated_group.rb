# frozen_string_literal: true

module RuboCop
  module Cop
    module Bundler
      # A Gem group, or a set of groups, should be listed only once in a Gemfile.
      #
      # For example, if the values of `source`, `git`, `platforms`, or `path`
      # surrounding `group` are different, no offense will be registered:
      #
      # [source,ruby]
      # -----
      # platforms :ruby do
      #   group :default do
      #     gem 'openssl'
      #   end
      # end
      #
      # platforms :jruby do
      #   group :default do
      #     gem 'jruby-openssl'
      #   end
      # end
      # -----
      #
      # @example
      #   # bad
      #   group :development do
      #     gem 'rubocop'
      #   end
      #
      #   group :development do
      #     gem 'rubocop-rails'
      #   end
      #
      #   # bad (same set of groups declared twice)
      #   group :development, :test do
      #     gem 'rubocop'
      #   end
      #
      #   group :test, :development do
      #     gem 'rspec'
      #   end
      #
      #   # good
      #   group :development do
      #     gem 'rubocop'
      #   end
      #
      #   group :development, :test do
      #     gem 'rspec'
      #   end
      #
      #   # good
      #   gem 'rubocop', groups: [:development, :test]
      #   gem 'rspec', groups: [:development, :test]
      #
      class DuplicatedGroup < Base
        include RangeHelp

        MSG = 'Gem group `%<group_name>s` already defined on line ' \
              '%<line_of_first_occurrence>d of the Gemfile.'
        SOURCE_BLOCK_NAMES = %i[source git platforms path].freeze

        # @!method group_declarations(node)
        def_node_search :group_declarations, '(send nil? :group ...)'

        def on_new_investigation
          return if processed_source.blank?

          duplicated_group_nodes.each do |nodes|
            nodes[1..].each do |node|
              group_name = node.arguments.map(&:source).join(', ')

              register_offense(node, group_name, nodes.first.first_line)
            end
          end
        end

        private

        def duplicated_group_nodes
          group_declarations = group_declarations(processed_source.ast)
          group_keys = group_declarations.group_by do |node|
            source_key = find_source_key(node)
            group_attributes = group_attributes(node).sort.join

            "#{source_key}#{group_attributes}"
          end

          group_keys.values.select { |nodes| nodes.size > 1 }
        end

        def register_offense(node, group_name, line_of_first_occurrence)
          line_range = node.loc.column...node.loc.last_column
          offense_location = source_range(processed_source.buffer, node.first_line, line_range)
          message = format(
            MSG,
            group_name: group_name,
            line_of_first_occurrence: line_of_first_occurrence
          )
          add_offense(offense_location, message: message)
        end

        def find_source_key(node)
          source_block = node.each_ancestor(:block).find do |block_node|
            SOURCE_BLOCK_NAMES.include?(block_node.method_name)
          end

          return unless source_block

          "#{source_block.method_name}#{source_block.send_node.first_argument&.source}"
        end

        def group_attributes(node)
          node.arguments.map do |argument|
            if argument.hash_type?
              argument.pairs.map(&:source).sort.join(', ')
            else
              argument.respond_to?(:value) ? argument.value.to_s : argument.source
            end
          end
        end
      end
    end
  end
end
