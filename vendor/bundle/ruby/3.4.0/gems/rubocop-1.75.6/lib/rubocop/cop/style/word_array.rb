# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for array literals made up of word-like
      # strings, that are not using the %w() syntax.
      #
      # Alternatively, it can check for uses of the %w() syntax, in projects
      # which do not want to include that syntax.
      #
      # NOTE: When using the `percent` style, %w() arrays containing a space
      # will be registered as offenses.
      #
      # Configuration option: MinSize
      # If set, arrays with fewer elements than this value will not trigger the
      # cop. For example, a `MinSize` of `3` will not enforce a style on an
      # array of 2 or fewer elements.
      #
      # @example EnforcedStyle: percent (default)
      #   # good
      #   %w[foo bar baz]
      #
      #   # bad
      #   ['foo', 'bar', 'baz']
      #
      #   # bad (contains spaces)
      #   %w[foo\ bar baz\ quux]
      #
      #   # bad
      #   [
      #     ['one', 'One'],
      #     ['two', 'Two']
      #   ]
      #
      #   # good
      #   [
      #     %w[one One],
      #     %w[two Two]
      #   ]
      #
      #   # good (2d array containing spaces)
      #   [
      #     ['one', 'One'],
      #     ['two', 'Two'],
      #     ['forty two', 'Forty Two']
      #   ]
      #
      # @example EnforcedStyle: brackets
      #   # good
      #   ['foo', 'bar', 'baz']
      #
      #   # bad
      #   %w[foo bar baz]
      #
      #   # good (contains spaces)
      #   ['foo bar', 'baz quux']
      #
      #   # good
      #   [
      #     ['one', 'One'],
      #     ['two', 'Two']
      #   ]
      #
      #   # bad
      #   [
      #     %w[one One],
      #     %w[two Two]
      #   ]
      #
      class WordArray < Base
        include ArrayMinSize
        include ArraySyntax
        include ConfigurableEnforcedStyle
        include PercentArray
        extend AutoCorrector

        PERCENT_MSG = 'Use `%w` or `%W` for an array of words.'
        ARRAY_MSG = 'Use %<prefer>s for an array of words.'

        class << self
          attr_accessor :largest_brackets
        end

        def on_new_investigation
          super

          # Prevent O(n2) checks (checking the entire matrix once for each child array) by caching
          @matrix_of_complex_content_cache = Hash.new do |cache, node|
            cache[node] = matrix_of_complex_content?(node)
          end
        end

        def on_array(node)
          if bracketed_array_of?(:str, node)
            return if complex_content?(node.values)
            return if within_matrix_of_complex_content?(node)

            check_bracketed_array(node, 'w')
          elsif node.percent_literal?(:string)
            check_percent_array(node)
          end
        end

        private

        def within_matrix_of_complex_content?(node)
          return false unless (parent = node.parent)

          parent.array_type? && @matrix_of_complex_content_cache[parent]
        end

        def matrix_of_complex_content?(array)
          array.values.all?(&:array_type?) &&
            array.values.any? { |subarray| complex_content?(subarray.values) }
        end

        def complex_content?(strings, complex_regex: word_regex)
          strings.any? do |s|
            next unless s.str_content

            string = s.str_content.dup.force_encoding(::Encoding::UTF_8)
            !string.valid_encoding? ||
              (complex_regex && !complex_regex.match?(string)) ||
              string.include?(' ')
          end
        end

        def invalid_percent_array_contents?(node)
          # Disallow %w() arrays that contain invalid encoding or spaces
          complex_content?(node.values, complex_regex: false)
        end

        def word_regex
          Regexp.new(cop_config['WordRegex'])
        end

        def build_bracketed_array(node)
          return '[]' if node.children.empty?

          words = node.children.map do |word|
            if word.dstr_type?
              string_literal = to_string_literal(word.source)

              trim_string_interpolation_escape_character(string_literal)
            else
              to_string_literal(word.children[0])
            end
          end
          build_bracketed_array_with_appropriate_whitespace(elements: words, node: node)
        end
      end
    end
  end
end
