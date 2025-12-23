# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for interpolated literals.
      #
      # NOTE: Array literals interpolated in regexps are not handled by this cop, but
      # by `Lint/ArrayLiteralInRegexp` instead.
      #
      # @example
      #
      #   # bad
      #   "result is #{10}"
      #
      #   # good
      #   "result is 10"
      class LiteralInInterpolation < Base
        include Interpolation
        include RangeHelp
        include PercentLiteral
        extend AutoCorrector

        MSG = 'Literal interpolation detected.'
        COMPOSITE = %i[array hash pair irange erange].freeze

        # rubocop:disable Metrics/AbcSize
        def on_interpolation(begin_node)
          final_node = begin_node.children.last
          return unless offending?(final_node)

          # %W and %I split the content into words before expansion
          # treating each interpolation as a word component, so
          # interpolation should not be removed if the expanded value
          # contains a space character.
          expanded_value = autocorrected_value(final_node)
          expanded_value = handle_special_regexp_chars(begin_node, expanded_value)

          return if in_array_percent_literal?(begin_node) && /\s|\A\z/.match?(expanded_value)

          add_offense(final_node) do |corrector|
            next if final_node.dstr_type? # nested, fixed in next iteration

            replacement = if final_node.str_type? && !final_node.value.valid_encoding?
                            final_node.source.delete_prefix('"').delete_suffix('"')
                          else
                            expanded_value
                          end

            corrector.replace(final_node.parent, replacement)
          end
        end
        # rubocop:enable Metrics/AbcSize

        private

        def offending?(node)
          node &&
            !special_keyword?(node) &&
            prints_as_self?(node) &&
            # Special case for `Layout/TrailingWhitespace`
            !(space_literal?(node) && ends_heredoc_line?(node)) &&
            # Handled by `Lint/ArrayLiteralInRegexp`
            !array_in_regexp?(node)
        end

        def special_keyword?(node)
          # handle strings like __FILE__
          (node.str_type? && !node.loc.respond_to?(:begin)) || node.source_range.is?('__LINE__')
        end

        def array_in_regexp?(node)
          grandparent = node.parent.parent
          node.array_type? && grandparent.regexp_type?
        end

        # rubocop:disable Metrics/MethodLength, Metrics/CyclomaticComplexity
        def autocorrected_value(node)
          case node.type
          when :int
            node.children.last.to_i.to_s
          when :float
            node.children.last.to_f.to_s
          when :str
            autocorrected_value_for_string(node)
          when :sym
            autocorrected_value_for_symbol(node)
          when :array
            autocorrected_value_for_array(node)
          when :hash
            autocorrected_value_for_hash(node)
          when :nil
            ''
          else
            node.source.gsub('"', '\"')
          end
        end
        # rubocop:enable Metrics/MethodLength, Metrics/CyclomaticComplexity

        def handle_special_regexp_chars(begin_node, value)
          parent_node = begin_node.parent

          return value unless parent_node.regexp_type? && parent_node.slash_literal? && value['/']

          # When a literal string containing a forward slash preceded by backslashes
          # is interpolated inside a regexp, the number of resultant backslashes in the
          # compiled Regexp is `(2(n+1) / 4)+1`, where `n` is the number of backslashes
          # inside the interpolation.
          # ie. 0-2 backslashes is compiled to 1, 3-6 is compiled to 3, etc.
          # This maintains that same behavior in order to ensure the Regexp behavior
          # does not change upon removing the interpolation.
          value.gsub(%r{(\\*)/}) do
            backslashes = Regexp.last_match[1]
            backslash_count = backslashes.length
            needed_backslashes = (2 * ((backslash_count + 1) / 4)) + 1

            "#{'\\' * needed_backslashes}/"
          end
        end

        def autocorrected_value_for_string(node)
          if node.source.start_with?("'", '%q')
            node.children.last.inspect[1..-2]
          else
            node.children.last
          end
        end

        def autocorrected_value_for_symbol(node)
          end_pos =
            node.loc.end ? node.loc.end.begin_pos : node.source_range.end_pos

          range_between(node.loc.begin.end_pos, end_pos).source.gsub('"', '\"')
        end

        def autocorrected_value_in_hash_for_symbol(node)
          # TODO: We need to detect symbol unacceptable names more correctly
          if / |"|'/.match?(node.value.to_s)
            ":\\\"#{node.value.to_s.gsub('"') { '\\\\\"' }}\\\""
          else
            ":#{node.value}"
          end
        end

        def autocorrected_value_for_array(node)
          return node.source.gsub('"', '\"') unless node.percent_literal?

          contents_range(node).source.split.to_s.gsub('"', '\"')
        end

        def autocorrected_value_for_hash(node)
          hash_string = node.children.map do |child|
            key = autocorrected_value_in_hash(child.key)
            value = autocorrected_value_in_hash(child.value)
            "#{key}=>#{value}"
          end.join(', ')

          "{#{hash_string}}"
        end

        # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        def autocorrected_value_in_hash(node)
          case node.type
          when :int
            node.children.last.to_i.to_s
          when :float
            node.children.last.to_f.to_s
          when :str
            "\\\"#{node.value.to_s.gsub('"') { '\\\\\"' }}\\\""
          when :sym
            autocorrected_value_in_hash_for_symbol(node)
          when :array
            autocorrected_value_for_array(node)
          when :hash
            autocorrected_value_for_hash(node)
          else
            node.source.gsub('"', '\"')
          end
        end
        # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

        # Does node print its own source when converted to a string?
        def prints_as_self?(node)
          node.basic_literal? ||
            (COMPOSITE.include?(node.type) && node.children.all? { |child| prints_as_self?(child) })
        end

        def space_literal?(node)
          node.str_type? && node.value.valid_encoding? && node.value.blank?
        end

        def ends_heredoc_line?(node)
          grandparent = node.parent.parent
          return false unless grandparent&.dstr_type? && grandparent.heredoc?

          line = processed_source.lines[node.last_line - 1]
          line.size == node.loc.last_column + 1
        end

        def in_array_percent_literal?(node)
          parent = node.parent
          return false unless parent.type?(:dstr, :dsym)

          grandparent = parent.parent
          grandparent&.array_type? && grandparent.percent_literal?
        end
      end
    end
  end
end
