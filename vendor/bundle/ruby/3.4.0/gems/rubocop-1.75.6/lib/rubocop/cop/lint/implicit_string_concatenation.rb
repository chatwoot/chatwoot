# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for implicit string concatenation of string literals
      # which are on the same line.
      #
      # @example
      #
      #   # bad
      #   array = ['Item 1' 'Item 2']
      #
      #   # good
      #   array = ['Item 1Item 2']
      #   array = ['Item 1' + 'Item 2']
      #   array = [
      #     'Item 1' \
      #     'Item 2'
      #   ]
      class ImplicitStringConcatenation < Base
        extend AutoCorrector

        MSG = 'Combine %<lhs>s and %<rhs>s into a single string ' \
              'literal, rather than using implicit string concatenation.'
        FOR_ARRAY = ' Or, if they were intended to be separate array ' \
                    'elements, separate them with a comma.'
        FOR_METHOD = ' Or, if they were intended to be separate method ' \
                     'arguments, separate them with a comma.'

        # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity
        def on_dstr(node)
          each_bad_cons(node) do |lhs_node, rhs_node|
            range = lhs_node.source_range.join(rhs_node.source_range)
            message = format(MSG, lhs: display_str(lhs_node), rhs: display_str(rhs_node))
            if node.parent&.array_type?
              message << FOR_ARRAY
            elsif node.parent&.send_type?
              message << FOR_METHOD
            end

            add_offense(range, message: message) do |corrector|
              if lhs_node.value == ''
                corrector.remove(lhs_node)
              elsif rhs_node.value == ''
                corrector.remove(rhs_node)
              else
                range = lhs_node.source_range.end.join(rhs_node.source_range.begin)

                corrector.replace(range, ' + ')
              end
            end
          end
        end
        # rubocop:enable Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity

        private

        def each_bad_cons(node)
          node.children.each_cons(2) do |child_node1, child_node2|
            # `'abc' 'def'` -> (dstr (str "abc") (str "def"))
            next unless string_literals?(child_node1, child_node2)
            next unless child_node1.last_line == child_node2.first_line

            # Make sure we don't flag a string literal which simply has
            # embedded newlines
            # `"abc\ndef"` also -> (dstr (str "abc") (str "def"))
            next unless child_node1.source[-1] == ending_delimiter(child_node1)

            yield child_node1, child_node2
          end
        end

        def ending_delimiter(str)
          # implicit string concatenation does not work with %{}, etc.
          case str.source[0]
          when "'"
            "'"
          when '"'
            '"'
          end
        end

        def string_literal?(node)
          node.type?(:str, :dstr)
        end

        def string_literals?(node1, node2)
          string_literal?(node1) && string_literal?(node2)
        end

        def display_str(node)
          if node.source.include?("\n")
            str_content(node).inspect
          else
            node.source
          end
        end

        def str_content(node)
          return unless node.respond_to?(:str_type?)

          if node.str_type?
            node.children[0]
          else
            node.children.map { |c| str_content(c) }.join
          end
        end
      end
    end
  end
end
