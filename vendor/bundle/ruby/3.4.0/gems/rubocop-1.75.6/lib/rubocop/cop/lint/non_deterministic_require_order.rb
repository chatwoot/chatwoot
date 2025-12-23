# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # `Dir[...]` and `Dir.glob(...)` do not make any guarantees about
      # the order in which files are returned. The final order is
      # determined by the operating system and file system.
      # This means that using them in cases where the order matters,
      # such as requiring files, can lead to intermittent failures
      # that are hard to debug. To ensure this doesn't happen,
      # always sort the list.
      #
      # `Dir.glob` and `Dir[]` sort globbed results by default in Ruby 3.0.
      # So all bad cases are acceptable when Ruby 3.0 or higher are used.
      #
      # NOTE: This cop will be deprecated and removed when supporting only Ruby 3.0 and higher.
      #
      # @safety
      #   This cop is unsafe in the case where sorting files changes existing
      #   expected behavior.
      #
      # @example
      #
      #   # bad
      #   Dir["./lib/**/*.rb"].each do |file|
      #     require file
      #   end
      #
      #   # good
      #   Dir["./lib/**/*.rb"].sort.each do |file|
      #     require file
      #   end
      #
      #   # bad
      #   Dir.glob(Rails.root.join(__dir__, 'test', '*.rb')) do |file|
      #     require file
      #   end
      #
      #   # good
      #   Dir.glob(Rails.root.join(__dir__, 'test', '*.rb')).sort.each do |file|
      #     require file
      #   end
      #
      #   # bad
      #   Dir['./lib/**/*.rb'].each(&method(:require))
      #
      #   # good
      #   Dir['./lib/**/*.rb'].sort.each(&method(:require))
      #
      #   # bad
      #   Dir.glob(Rails.root.join('test', '*.rb'), &method(:require))
      #
      #   # good
      #   Dir.glob(Rails.root.join('test', '*.rb')).sort.each(&method(:require))
      #
      #   # good - Respect intent if `sort` keyword option is specified in Ruby 3.0 or higher.
      #   Dir.glob(Rails.root.join(__dir__, 'test', '*.rb'), sort: false).each(&method(:require))
      #
      class NonDeterministicRequireOrder < Base
        extend AutoCorrector
        extend TargetRubyVersion

        MSG = 'Sort files before requiring them.'

        maximum_target_ruby_version 2.7

        def on_block(node)
          return unless node.body
          return unless unsorted_dir_loop?(node.send_node)

          loop_variable(node.arguments) do |var_name|
            return unless var_is_required?(node.body, var_name)

            add_offense(node.send_node) { |corrector| correct_block(corrector, node.send_node) }
          end
        end

        def on_numblock(node)
          return unless node.body
          return unless unsorted_dir_loop?(node.send_node)

          node.argument_list
              .filter { |argument| var_is_required?(node.body, argument.name) }
              .each do
                add_offense(node.send_node) { |corrector| correct_block(corrector, node.send_node) }
              end
        end

        def on_block_pass(node)
          return unless method_require?(node)
          return unless unsorted_dir_pass?(node.parent)

          parent_node = node.parent

          add_offense(parent_node) do |corrector|
            if parent_node.last_argument&.block_pass_type?
              correct_block_pass(corrector, parent_node)
            else
              correct_block(corrector, parent_node)
            end
          end
        end

        private

        def correct_block(corrector, node)
          if unsorted_dir_block?(node)
            corrector.replace(node, "#{node.source}.sort.each")
          else
            source = node.receiver.source

            corrector.replace(node, "#{source}.sort.each")
          end
        end

        def correct_block_pass(corrector, node)
          if unsorted_dir_glob_pass?(node)
            block_arg = node.last_argument

            corrector.remove(last_arg_range(node))
            corrector.insert_after(node, ".sort.each(#{block_arg.source})")
          else
            corrector.replace(node.loc.selector, 'sort.each')
          end
        end

        # Returns range of last argument including comma and whitespace.
        #
        # @return [Parser::Source::Range]
        #
        def last_arg_range(node)
          node.last_argument.source_range.join(node.arguments[-2].source_range.end)
        end

        def unsorted_dir_loop?(node)
          unsorted_dir_block?(node) || unsorted_dir_each?(node)
        end

        def unsorted_dir_pass?(node)
          unsorted_dir_glob_pass?(node) || unsorted_dir_each_pass?(node)
        end

        # @!method unsorted_dir_block?(node)
        def_node_matcher :unsorted_dir_block?, <<~PATTERN
          (send (const {nil? cbase} :Dir) :glob ...)
        PATTERN

        # @!method unsorted_dir_each?(node)
        def_node_matcher :unsorted_dir_each?, <<~PATTERN
          (send (send (const {nil? cbase} :Dir) {:[] :glob} ...) :each)
        PATTERN

        # @!method method_require?(node)
        def_node_matcher :method_require?, <<~PATTERN
          (block-pass (send nil? :method (sym {:require :require_relative})))
        PATTERN

        # @!method unsorted_dir_glob_pass?(node)
        def_node_matcher :unsorted_dir_glob_pass?, <<~PATTERN
          (send (const {nil? cbase} :Dir) :glob ...
            (block-pass (send nil? :method (sym {:require :require_relative}))))
        PATTERN

        # @!method unsorted_dir_each_pass?(node)
        def_node_matcher :unsorted_dir_each_pass?, <<~PATTERN
          (send (send (const {nil? cbase} :Dir) {:[] :glob} ...) :each
            (block-pass (send nil? :method (sym {:require :require_relative}))))
        PATTERN

        # @!method loop_variable(node)
        def_node_matcher :loop_variable, <<~PATTERN
          (args (arg $_))
        PATTERN

        # @!method var_is_required?(node, name)
        def_node_search :var_is_required?, <<~PATTERN
          (send nil? {:require :require_relative} (lvar %1))
        PATTERN
      end
    end
  end
end
