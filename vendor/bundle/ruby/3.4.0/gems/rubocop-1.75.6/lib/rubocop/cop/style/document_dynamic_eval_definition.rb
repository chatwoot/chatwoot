# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # When using `class_eval` (or other `eval`) with string interpolation,
      # add a comment block showing its appearance if interpolated (a practice used in Rails code).
      #
      # @example
      #   # from activesupport/lib/active_support/core_ext/string/output_safety.rb
      #
      #   # bad
      #   UNSAFE_STRING_METHODS.each do |unsafe_method|
      #     if 'String'.respond_to?(unsafe_method)
      #       class_eval <<-EOT, __FILE__, __LINE__ + 1
      #         def #{unsafe_method}(*params, &block)
      #           to_str.#{unsafe_method}(*params, &block)
      #         end
      #
      #         def #{unsafe_method}!(*params)
      #           @dirty = true
      #           super
      #         end
      #       EOT
      #     end
      #   end
      #
      #   # good, inline comments in heredoc
      #   UNSAFE_STRING_METHODS.each do |unsafe_method|
      #     if 'String'.respond_to?(unsafe_method)
      #       class_eval <<-EOT, __FILE__, __LINE__ + 1
      #         def #{unsafe_method}(*params, &block)       # def capitalize(*params, &block)
      #           to_str.#{unsafe_method}(*params, &block)  #   to_str.capitalize(*params, &block)
      #         end                                         # end
      #
      #         def #{unsafe_method}!(*params)              # def capitalize!(*params)
      #           @dirty = true                             #   @dirty = true
      #           super                                     #   super
      #         end                                         # end
      #       EOT
      #     end
      #   end
      #
      #   # good, block comments in heredoc
      #   class_eval <<-EOT, __FILE__, __LINE__ + 1
      #     # def capitalize!(*params)
      #     #   @dirty = true
      #     #   super
      #     # end
      #
      #     def #{unsafe_method}!(*params)
      #       @dirty = true
      #       super
      #     end
      #   EOT
      #
      #   # good, block comments before heredoc
      #   class_eval(
      #     # def capitalize!(*params)
      #     #   @dirty = true
      #     #   super
      #     # end
      #
      #     <<-EOT, __FILE__, __LINE__ + 1
      #       def #{unsafe_method}!(*params)
      #         @dirty = true
      #         super
      #       end
      #     EOT
      #   )
      #
      #   # bad - interpolated string without comment
      #   class_eval("def #{unsafe_method}!(*params); end")
      #
      #   # good - with inline comment or replace it with block comment using heredoc
      #   class_eval("def #{unsafe_method}!(*params); end # def capitalize!(*params); end")
      class DocumentDynamicEvalDefinition < Base
        BLOCK_COMMENT_REGEXP = /^\s*#(?!{)/.freeze
        COMMENT_REGEXP = /\s*#(?!{).*/.freeze
        MSG = 'Add a comment block showing its appearance if interpolated.'

        RESTRICT_ON_SEND = %i[eval class_eval module_eval instance_eval].freeze

        def on_send(node)
          arg_node = node.first_argument

          return unless arg_node&.dstr_type? && interpolated?(arg_node)
          return if inline_comment_docs?(arg_node) ||
                    (arg_node.heredoc? && comment_block_docs?(arg_node))

          add_offense(node.loc.selector)
        end

        private

        def interpolated?(arg_node)
          arg_node.each_child_node(:begin).any?
        end

        def inline_comment_docs?(node)
          node.each_child_node(:begin).all? do |begin_node|
            source_line = processed_source.lines[begin_node.first_line - 1]
            source_line.match?(COMMENT_REGEXP)
          end
        end

        def comment_block_docs?(arg_node)
          comments = heredoc_comment_blocks(arg_node.loc.heredoc_body.line_span)
                     .concat(preceding_comment_blocks(arg_node.parent))

          return false if comments.none?

          regexp = comment_regexp(arg_node)
          comments.any?(regexp) || regexp.match?(comments.join)
        end

        def preceding_comment_blocks(node)
          # Collect comments in the method call, but outside the heredoc
          comments = processed_source.each_comment_in_lines(node.source_range.line_span)

          comments.each_with_object({}) do |comment, hash|
            merge_adjacent_comments(comment.text, comment.loc.line, hash)
          end.values
        end

        def heredoc_comment_blocks(heredoc_body)
          # Collect comments inside the heredoc
          line_range = (heredoc_body.begin - 1)..(heredoc_body.end - 1)
          lines = processed_source.lines[line_range]

          lines.each_with_object({}).with_index(line_range.begin) do |(line, hash), index|
            merge_adjacent_comments(line, index, hash)
          end.values
        end

        def merge_adjacent_comments(line, index, hash)
          # Combine adjacent comment lines into a single string
          return unless (line = line.dup.gsub!(BLOCK_COMMENT_REGEXP, ''))

          hash[index] = if hash.keys.last == index - 1
                          [hash.delete(index - 1), line].join("\n")
                        else
                          line
                        end
        end

        def comment_regexp(arg_node)
          # Replace the interpolations with wildcards
          regexp_parts = arg_node.child_nodes.map do |n|
            n.begin_type? ? /.+/ : source_to_regexp(n.source)
          end

          Regexp.new(regexp_parts.join)
        end

        def source_to_regexp(source)
          # Get the source in the heredoc being `eval`ed, without any comments
          # and turn it into a regexp
          return /\s+/ if source.blank?

          source = source.gsub(COMMENT_REGEXP, '')
          return if source.blank?

          /\s*#{Regexp.escape(source.strip)}/
        end
      end
    end
  end
end
