# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for uses of if/unless modifiers with multiple-lines bodies.
      #
      # @example
      #
      #   # bad
      #   {
      #     result: 'this should not happen'
      #   } unless cond
      #
      #   # good
      #   { result: 'ok' } if cond
      class MultilineIfModifier < Base
        include StatementModifier
        include Alignment
        extend AutoCorrector

        MSG = 'Favor a normal %<keyword>s-statement over a modifier ' \
              'clause in a multiline statement.'

        def on_if(node)
          return if part_of_ignored_node?(node)
          return unless node.modifier_form? && node.body.multiline?

          add_offense(node, message: format(MSG, keyword: node.keyword)) do |corrector|
            corrector.replace(node, to_normal_if(node))
          end
          ignore_node(node)
        end

        private

        def to_normal_if(node)
          indented_body = indented_body(node.body, node)
          condition = "#{node.keyword} #{node.condition.source}"
          indented_end = "#{offset(node)}end"

          [condition, indented_body, indented_end].join("\n")
        end

        def indented_body(body, node)
          body_source = "#{offset(node)}#{body.source}"
          body_source.each_line.map do |line|
            if line == "\n"
              line
            else
              line.sub(/^\s{#{offset(node).length}}/, indentation(node))
            end
          end.join
        end
      end
    end
  end
end
