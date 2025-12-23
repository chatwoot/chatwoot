# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # This lint sees if there is a mismatch between the number of
      # expected fields for format/sprintf/#% and what is actually
      # passed as arguments.
      #
      # In addition, it checks whether different formats are used in the same
      # format string. Do not mix numbered, unnumbered, and named formats in
      # the same format string.
      #
      # @example
      #
      #   # bad
      #   format('A value: %s and another: %i', a_value)
      #
      #   # good
      #   format('A value: %s and another: %i', a_value, another)
      #
      #   # bad
      #   format('Unnumbered format: %s and numbered: %2$s', a_value, another)
      #
      #   # good
      #   format('Numbered format: %1$s and numbered %2$s', a_value, another)
      class FormatParameterMismatch < Base
        # http://rubular.com/r/CvpbxkcTzy
        MSG = "Number of arguments (%<arg_num>i) to `%<method>s` doesn't " \
              'match the number of fields (%<field_num>i).'
        MSG_INVALID = 'Format string is invalid because formatting sequence types ' \
                      '(numbered, named or unnumbered) are mixed.'

        KERNEL = 'Kernel'
        SHOVEL = '<<'
        STRING_TYPES = %i[str dstr].freeze
        RESTRICT_ON_SEND = %i[format sprintf %].freeze

        def on_send(node)
          return unless format_string?(node)

          if invalid_format_string?(node)
            add_offense(node.loc.selector, message: MSG_INVALID)
            return
          end

          return unless offending_node?(node)

          add_offense(node.loc.selector, message: message(node))
        end

        private

        def format_string?(node)
          called_on_string?(node) && method_with_format_args?(node)
        end

        def invalid_format_string?(node)
          string = if sprintf?(node) || format?(node)
                     node.first_argument.source
                   else
                     node.receiver.source
                   end
          !RuboCop::Cop::Utils::FormatString.new(string).valid?
        end

        def offending_node?(node)
          return false if splat_args?(node)

          num_of_format_args, num_of_expected_fields = count_matches(node)

          return false if num_of_format_args == :unknown

          first_arg = node.first_argument
          return false if num_of_expected_fields.zero? &&
                          first_arg.type?(:dstr, :array)

          matched_arguments_count?(num_of_expected_fields, num_of_format_args)
        end

        def matched_arguments_count?(expected, passed)
          if passed.negative?
            expected < passed.abs
          else
            expected != passed
          end
        end

        # @!method called_on_string?(node)
        def_node_matcher :called_on_string?, <<~PATTERN
          {(send {nil? const_type?} _ {str dstr} ...)
           (send {str dstr} ...)}
        PATTERN

        def method_with_format_args?(node)
          sprintf?(node) || format?(node) || percent?(node)
        end

        def splat_args?(node)
          return false if percent?(node)

          node.arguments.drop(1).any?(&:splat_type?)
        end

        def heredoc?(node)
          node.first_argument.source[0, 2] == SHOVEL
        end

        def count_matches(node)
          if countable_format?(node)
            count_format_matches(node)
          elsif countable_percent?(node)
            count_percent_matches(node)
          else
            [:unknown] * 2
          end
        end

        def countable_format?(node)
          (sprintf?(node) || format?(node)) && !heredoc?(node)
        end

        def countable_percent?(node)
          percent?(node) && node.first_argument.array_type?
        end

        def count_format_matches(node)
          [node.arguments.count - 1, expected_fields_count(node.first_argument)]
        end

        def count_percent_matches(node)
          [node.first_argument.child_nodes.count,
           expected_fields_count(node.receiver)]
        end

        def format_method?(name, node)
          return false if node.const_receiver? && !node.receiver.loc.name.is?(KERNEL)
          return false unless node.method?(name)

          node.arguments.size > 1 && string_type?(node.first_argument)
        end

        def expected_fields_count(node)
          return :unknown unless string_type?(node)

          format_string = RuboCop::Cop::Utils::FormatString.new(node.source)
          return 1 if format_string.named_interpolation?

          max_digit_dollar_num = format_string.max_digit_dollar_num
          return max_digit_dollar_num if max_digit_dollar_num&.nonzero?

          format_string
            .format_sequences
            .reject(&:percent?)
            .reduce(0) { |acc, seq| acc + seq.arity }
        end

        def format?(node)
          format_method?(:format, node)
        end

        def sprintf?(node)
          format_method?(:sprintf, node)
        end

        def percent?(node)
          receiver = node.receiver

          percent = node.method?(:%) && (string_type?(receiver) || node.first_argument.array_type?)

          return false if percent && string_type?(receiver) && heredoc?(node)

          percent
        end

        def message(node)
          num_args_for_format, num_expected_fields = count_matches(node)

          method_name = node.method?(:%) ? 'String#%' : node.method_name

          format(MSG, arg_num: num_args_for_format, method: method_name,
                      field_num: num_expected_fields)
        end

        def string_type?(node)
          STRING_TYPES.include?(node.type)
        end
      end
    end
  end
end
