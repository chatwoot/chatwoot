# frozen_string_literal: true

module RuboCop
  module Cop
    module Performance
      # Checks for redundant `String#chars`.
      #
      # @example
      #   # bad
      #   str.chars[0..2]
      #   str.chars.slice(0..2)
      #   str.chars.last
      #
      #   # good
      #   str[0..2].chars
      #
      #   # bad
      #   str.chars.first
      #   str.chars.first(2)
      #
      #   # good
      #   str[0]
      #   str[0...2].chars
      #   str[-1]
      #
      #   # bad
      #   str.chars.take(2)
      #   str.chars.length
      #   str.chars.size
      #   str.chars.empty?
      #
      #   # good
      #   str[0...2].chars
      #   str.length
      #   str.size
      #   str.empty?
      #
      #   # For example, if the receiver is an empty string, it will be incompatible.
      #   # If a negative value is specified for the receiver, `nil` is returned.
      #   str.chars.last(2) # Incompatible with `str[-2..-1].chars`.
      #   str.chars.drop(2) # Incompatible with `str[2..-1].chars`.
      #
      class RedundantStringChars < Base
        include RangeHelp
        extend AutoCorrector

        MSG = 'Use `%<good_method>s` instead of `%<bad_method>s`.'
        RESTRICT_ON_SEND = %i[[] slice first last take length size empty?].freeze

        def_node_matcher :redundant_chars_call?, <<~PATTERN
          (send $(send !nil? :chars) $_ $...)
        PATTERN

        def on_send(node)
          return unless (receiver, method, args = redundant_chars_call?(node))
          return if method == :last && !args.empty?

          range = offense_range(receiver, node)
          message = build_message(method, args)

          add_offense(range, message: message) do |corrector|
            range = correction_range(receiver, node)
            replacement = build_good_method(method, args)

            corrector.replace(range, replacement)
          end
        end

        private

        def offense_range(receiver, node)
          range_between(receiver.loc.selector.begin_pos, node.source_range.end_pos)
        end

        def correction_range(receiver, node)
          range_between(receiver.loc.dot.begin_pos, node.source_range.end_pos)
        end

        def build_message(method, args)
          good_method = build_good_method(method, args)
          bad_method = build_bad_method(method, args)
          format(MSG, good_method: good_method, bad_method: bad_method)
        end

        def build_good_method(method, args)
          case method
          when :slice
            "[#{build_call_args(args)}].chars"
          when :[], :first
            build_good_method_for_brackets_or_first_method(method, args)
          when :last
            '[-1]'
          when :take
            "[0...#{args.first.source}].chars"
          else
            ".#{method}"
          end
        end

        def build_good_method_for_brackets_or_first_method(method, args)
          first_arg = args.first

          if first_arg&.range_type?
            "[#{build_call_args(args)}].chars"
          elsif method == :first && args.any?
            "[0...#{args.first.source}].chars"
          else
            first_arg ? "[#{first_arg.source}]" : '[0]'
          end
        end

        def build_bad_method(method, args)
          case method
          when :[]
            "chars[#{build_call_args(args)}]"
          else
            if args.any?
              "chars.#{method}(#{build_call_args(args)})"
            else
              "chars.#{method}"
            end
          end
        end

        def build_call_args(call_args_node)
          call_args_node.map(&:source).join(', ')
        end
      end
    end
  end
end
