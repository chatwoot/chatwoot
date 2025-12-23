# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for "triple quotes" (strings delimited by any odd number
      # of quotes greater than 1).
      #
      # Ruby allows multiple strings to be implicitly concatenated by just
      # being adjacent in a statement (ie. `"foo""bar" == "foobar"`). This sometimes
      # gives the impression that there is something special about triple quotes, but
      # in fact it is just extra unnecessary quotes and produces the same string. Each
      # pair of quotes produces an additional concatenated empty string, so the result
      # is still only the "actual" string within the delimiters.
      #
      # NOTE: Although this cop is called triple quotes, the same behavior is present
      # for strings delimited by 5, 7, etc. quotation marks.
      #
      # @example
      #   # bad
      #   """
      #     A string
      #   """
      #
      #   # bad
      #   '''
      #     A string
      #   '''
      #
      #   # good
      #   "
      #     A string
      #   "
      #
      #   # good
      #   <<STRING
      #     A string
      #   STRING
      #
      #   # good (but not the same spacing as the bad case)
      #   'A string'
      class TripleQuotes < Base
        extend AutoCorrector

        MSG = 'Delimiting a string with multiple quotes has no effect, use a single quote instead.'

        def on_dstr(node)
          return if (empty_str_nodes = empty_str_nodes(node)).none?

          opening_quotes = node.source.scan(/(?<=\A)['"]*/)[0]
          return if opening_quotes.size < 3

          # If the node is composed of only empty `str` nodes, keep one
          empty_str_nodes.shift if empty_str_nodes.size == node.child_nodes.size

          add_offense(node) do |corrector|
            empty_str_nodes.each do |str|
              corrector.remove(str)
            end
          end
        end

        private

        def empty_str_nodes(node)
          node.each_child_node(:str).select { |str| str.value == '' }
        end
      end
    end
  end
end
