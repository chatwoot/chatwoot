# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for nested `File.dirname`.
      # It replaces nested `File.dirname` with the level argument introduced in Ruby 3.1.
      #
      # @example
      #
      #   # bad
      #   File.dirname(File.dirname(path))
      #
      #   # good
      #   File.dirname(path, 2)
      #
      class NestedFileDirname < Base
        include RangeHelp
        extend AutoCorrector
        extend TargetRubyVersion

        MSG = 'Use `dirname(%<path>s, %<level>s)` instead.'
        RESTRICT_ON_SEND = %i[dirname].freeze

        minimum_target_ruby_version 3.1

        # @!method file_dirname?(node)
        def_node_matcher :file_dirname?, <<~PATTERN
          (send
            (const {cbase nil?} :File) :dirname ...)
        PATTERN

        def on_send(node)
          return if file_dirname?(node.parent) || !file_dirname?(node.first_argument)

          path, level = path_with_dir_level(node, 1)
          return if level < 2

          message = format(MSG, path: path, level: level)
          range = offense_range(node)

          add_offense(range, message: message) do |corrector|
            corrector.replace(range, "dirname(#{path}, #{level})")
          end
        end

        private

        def path_with_dir_level(node, level)
          first_argument = node.first_argument

          if file_dirname?(first_argument)
            level += 1
            path_with_dir_level(first_argument, level)
          else
            [first_argument.source, level]
          end
        end

        def offense_range(node)
          range_between(node.loc.selector.begin_pos, node.source_range.end_pos)
        end
      end
    end
  end
end
