# frozen_string_literal: true

module RuboCop
  module Cop
    module InternalAffairs
      # Checks that node matcher definitions are tagged with a YARD `@!method`
      # directive so that editors are able to find the dynamically defined
      # method.
      #
      # @example
      #  # bad
      #  def_node_matcher :foo?, <<~PATTERN
      #    ...
      #  PATTERN
      #
      #  # good
      #  # @!method foo?(node)
      #  def_node_matcher :foo?, <<~PATTERN
      #    ...
      #  PATTERN
      #
      class NodeMatcherDirective < Base
        extend AutoCorrector
        include RangeHelp

        MSG = 'Precede `%<method>s` with a `@!method` YARD directive.'
        MSG_WRONG_NAME = '`@!method` YARD directive has invalid method name, ' \
                         'use `%<expected>s` instead of `%<actual>s`.'
        MSG_MISSING_SCOPE_SELF = 'Follow the `@!method` YARD directive with ' \
                                 '`@!scope class` if it is a class method.'
        MSG_WRONG_SCOPE_SELF = 'Do not use the `@!scope class` YARD directive if it ' \
                               'is not a class method.'
        MSG_TOO_MANY = 'Multiple `@!method` YARD directives found for this matcher.'

        RESTRICT_ON_SEND = %i[def_node_matcher def_node_search].to_set.freeze
        REGEXP_METHOD = /
          ^\s*\#\s*
          @!method\s+(?<receiver>self\.)?(?<method_name>[a-z0-9_]+[?!]?)(?:\((?<args>.*)\))?
        /x.freeze
        REGEXP_SCOPE = /^\s*\#\s*@!scope class/.freeze

        # @!method pattern_matcher?(node)
        def_node_matcher :pattern_matcher?, <<~PATTERN
          (send _ %RESTRICT_ON_SEND {str sym} {str dstr})
        PATTERN

        def on_send(node)
          return unless node.arguments.count == 2
          return unless valid_method_name?(node)

          actual_name = node.first_argument.value.to_s

          # Ignore cases where the method has a receiver that isn't self
          return if actual_name.include?('.') && !actual_name.start_with?('self.')

          directives = method_directives(node)
          return too_many_directives(node) if directives.size > 1

          process_directive(node, actual_name, directives.first)
        end

        private

        def valid_method_name?(node)
          node.first_argument.type?(:str, :sym)
        end

        def method_directives(node)
          comments = processed_source.ast_with_comments[node]
          group_comments(comments).filter_map do |comment_method, comment_scope|
            match = comment_method.text.match(REGEXP_METHOD)
            next unless match

            {
              node_method: comment_method,
              node_scope: comment_scope,
              method_name: match[:method_name],
              args: match[:args],
              receiver: match[:receiver],
              has_scope_directive: comment_scope&.text&.match?(REGEXP_SCOPE)
            }
          end
        end

        def group_comments(comments)
          result = []
          comments.each.with_index do |comment, index|
            # Grab the scope directive if it is preceded by a method directive
            if comment.text.include?('@!method')
              result << if (next_comment = comments[index + 1])&.text&.include?('@!scope')
                          [comment, next_comment]
                        else
                          [comment, nil]
                        end
            end
          end
          result
        end

        def too_many_directives(node)
          add_offense(node, message: MSG_TOO_MANY)
        end

        def process_directive(node, actual_name, directive)
          return unless (offense_type = directive_offense_type(directive, actual_name))

          register_offense(offense_type, node, directive, actual_name)
        end

        def directive_offense_type(directive, actual_name)
          return :missing_directive unless directive

          return :wrong_scope if wrong_scope(directive, actual_name)
          return :no_scope if no_scope(directive, actual_name)

          # The method directive being prefixed by 'self.' is always an offense.
          # The matched method_name does not contain the receiver but the
          # def_node_match method name may so it must be removed.
          if directive[:method_name] != remove_receiver(actual_name) || directive[:receiver]
            :wrong_name
          end
        end

        def wrong_scope(directive, actual_name)
          !actual_name.start_with?('self.') && directive[:has_scope_directive]
        end

        def no_scope(directive, actual_name)
          actual_name.start_with?('self.') && !directive[:has_scope_directive]
        end

        def register_offense(offense_type, node, directive, actual_name)
          message = formatted_message(offense_type, directive, actual_name, node.method_name)

          add_offense(node, message: message) do |corrector|
            case offense_type
            when :wrong_name
              correct_method_directive(corrector, directive, actual_name)
            when :wrong_scope
              remove_scope_directive(corrector, directive)
            when :no_scope
              insert_scope_directive(corrector, directive[:node_method])
            when :missing_directive
              insert_method_directive(corrector, node, actual_name)
            end
          end
        end

        # rubocop:disable Metrics/MethodLength
        def formatted_message(offense_type, directive, actual_name, method_name)
          case offense_type
          when :wrong_name
            # Add the receiver to the name when showing an offense
            current_name = if directive[:receiver]
                             directive[:receiver] + directive[:method_name]
                           else
                             directive[:method_name]
                           end
            # The correct name will never include a receiver, remove it
            format(MSG_WRONG_NAME, expected: remove_receiver(actual_name), actual: current_name)
          when :wrong_scope
            MSG_WRONG_SCOPE_SELF
          when :no_scope
            MSG_MISSING_SCOPE_SELF
          when :missing_directive
            format(MSG, method: method_name)
          end
        end
        # rubocop:enable Metrics/MethodLength

        def remove_receiver(current)
          current.delete_prefix('self.')
        end

        def insert_method_directive(corrector, node, actual_name)
          # If the pattern matcher uses arguments (`%1`, `%2`, etc.), include them in the directive
          arguments = pattern_arguments(node.arguments[1].source)

          range = range_with_surrounding_space(node.source_range, side: :left, newlines: false)
          indentation = range.source.match(/^\s*/)[0]
          directive = "#{indentation}# @!method #{actual_name}(#{arguments.join(', ')})\n"
          directive = "\n#{directive}" if add_newline?(node)

          corrector.insert_before(range, directive)
        end

        def insert_scope_directive(corrector, node)
          range = range_with_surrounding_space(node.source_range, side: :left, newlines: false)
          indentation = range.source.match(/^\s*/)[0]
          directive = "\n#{indentation}# @!scope class"

          corrector.insert_after(node, directive)
        end

        def pattern_arguments(pattern)
          arguments = %w[node]
          max_pattern_var = pattern.scan(/(?<=%)\d+/).map(&:to_i).max
          max_pattern_var&.times { |i| arguments << "arg#{i + 1}" }
          arguments
        end

        def add_newline?(node)
          # Determine if a blank line should be inserted before the new directive
          # in order to spread out pattern matchers
          return false if node.sibling_index&.zero?
          return false unless node.parent

          prev_sibling = node.parent.child_nodes[node.sibling_index - 1]
          return false unless prev_sibling && pattern_matcher?(prev_sibling)

          node.loc.line == last_line(prev_sibling) + 1
        end

        def last_line(node)
          if node.last_argument.heredoc?
            node.last_argument.loc.heredoc_end.line
          else
            node.loc.last_line
          end
        end

        def correct_method_directive(corrector, directive, actual_name)
          correct = "@!method #{remove_receiver(actual_name)}"
          current_name = (directive[:receiver] || '') + directive[:method_name]
          regexp = /@!method\s+#{Regexp.escape(current_name)}/

          replacement = directive[:node_method].text.gsub(regexp, correct)
          corrector.replace(directive[:node_method], replacement)
        end

        def remove_scope_directive(corrector, directive)
          range = range_by_whole_lines(
            directive[:node_scope].source_range,
            include_final_newline: true
          )
          corrector.remove(range)
        end
      end
    end
  end
end
