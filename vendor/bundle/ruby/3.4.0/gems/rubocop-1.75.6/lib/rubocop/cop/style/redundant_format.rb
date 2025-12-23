# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for calls to `Kernel#format` or `Kernel#sprintf` that are redundant.
      #
      # Calling `format` with only a single string or constant argument is redundant,
      # as it can be replaced by the string or constant itself.
      #
      # Also looks for `format` calls where the arguments are literals that can be
      # inlined into a string easily. This applies to the `%s`, `%d`, `%i`, `%u`, and
      # `%f` format specifiers.
      #
      # @safety
      #   This cop's autocorrection is unsafe because string object returned by
      #   `format` and `sprintf` are never frozen. If `format('string')` is autocorrected to
      #   `'string'`, `FrozenError` may occur when calling a destructive method like `String#<<`.
      #   Consider using `'string'.dup` instead of `format('string')`.
      #   Additionally, since the necessity of `dup` cannot be determined automatically,
      #   this autocorrection is inherently unsafe.
      #
      #   [source,ruby]
      #   ----
      #   # frozen_string_literal: true
      #
      #   format('template').frozen? # => false
      #   'template'.frozen?         # => true
      #   ----
      #
      # @example
      #
      #   # bad
      #   format('the quick brown fox jumps over the lazy dog.')
      #   sprintf('the quick brown fox jumps over the lazy dog.')
      #
      #   # good
      #   'the quick brown fox jumps over the lazy dog.'
      #
      #   # bad
      #   format(MESSAGE)
      #   sprintf(MESSAGE)
      #
      #   # good
      #   MESSAGE
      #
      #   # bad
      #   format('%s %s', 'foo', 'bar')
      #   sprintf('%s %s', 'foo', 'bar')
      #
      #   # good
      #   'foo bar'
      #
      class RedundantFormat < Base
        extend AutoCorrector

        MSG = 'Use `%<prefer>s` directly instead of `%<method_name>s`.'

        RESTRICT_ON_SEND = %i[format sprintf].to_set.freeze
        ACCEPTABLE_LITERAL_TYPES = %i[str dstr sym dsym numeric boolean nil].freeze

        # @!method format_without_additional_args?(node)
        def_node_matcher :format_without_additional_args?, <<~PATTERN
          (send {(const {nil? cbase} :Kernel) nil?} %RESTRICT_ON_SEND ${str dstr const})
        PATTERN

        # @!method rational_number?(node)
        def_node_matcher :rational_number?, <<~PATTERN
          {rational (send int :/ rational) (begin rational) (begin (send int :/ rational))}
        PATTERN

        # @!method complex_number?(node)
        def_node_matcher :complex_number?, <<~PATTERN
          {complex (send int :+ complex) (begin complex) (begin (send int :+ complex))}
        PATTERN

        # @!method find_hash_value_node(node, name)
        def_node_search  :find_hash_value_node, <<~PATTERN
          (pair (sym %1) $_)
        PATTERN

        # @!method splatted_arguments?(node)
        def_node_matcher :splatted_arguments?, <<~PATTERN
          (send _ %RESTRICT_ON_SEND <{
            splat
            (hash <kwsplat ...>)
          } ...>)
        PATTERN

        def on_send(node)
          format_without_additional_args?(node) do |value|
            replacement = value.source

            add_offense(node, message: message(node, replacement)) do |corrector|
              corrector.replace(node, replacement)
            end
            return
          end

          detect_unnecessary_fields(node)
        end

        private

        def message(node, prefer)
          format(MSG, prefer: prefer, method_name: node.method_name)
        end

        def detect_unnecessary_fields(node)
          return unless node.first_argument&.str_type?

          string = node.first_argument.value
          arguments = node.arguments[1..]

          return unless string && arguments.any?
          return if splatted_arguments?(node)

          register_all_fields_literal(node, string, arguments)
        end

        def register_all_fields_literal(node, string, arguments)
          return unless all_fields_literal?(string, arguments.dup)

          formatted_string = format(string, *argument_values(arguments))
          replacement = quote(formatted_string, node)

          add_offense(node, message: message(node, replacement)) do |corrector|
            corrector.replace(node, replacement)
          end
        end

        def all_fields_literal?(string, arguments)
          count = 0
          sequences = RuboCop::Cop::Utils::FormatString.new(string).format_sequences
          return false unless sequences.any?

          sequences.each do |sequence|
            next if sequence.percent?

            hash = arguments.detect(&:hash_type?)
            next unless (argument = find_argument(sequence, arguments, hash))
            next unless matching_argument?(sequence, argument)

            count += 1
          end

          sequences.size == count
        end

        def find_argument(sequence, arguments, hash)
          if hash && (sequence.annotated? || sequence.template?)
            find_hash_value_node(hash, sequence.name.to_sym).first
          elsif sequence.arg_number
            arguments[sequence.arg_number.to_i - 1]
          else
            # If the specifier contains `*`, the following arguments will be used
            # to specify the width and can be ignored.
            (sequence.arity - 1).times { arguments.shift }
            arguments.shift
          end
        end

        def matching_argument?(sequence, argument)
          # Template specifiers don't give a type, any acceptable literal type is ok.
          return argument.type?(*ACCEPTABLE_LITERAL_TYPES) if sequence.template?

          # An argument matches a specifier if it can be easily converted
          # to that type.
          case sequence.type
          when 's'
            argument.type?(*ACCEPTABLE_LITERAL_TYPES)
          when 'd', 'i', 'u'
            integer?(argument)
          when 'f'
            float?(argument)
          else
            false
          end
        end

        def numeric?(argument)
          argument.type?(:numeric, :str) ||
            rational_number?(argument) ||
            complex_number?(argument)
        end

        def integer?(argument)
          numeric?(argument) && Integer(argument_value(argument), exception: false)
        end

        def float?(argument)
          numeric?(argument) && Float(argument_value(argument), exception: false)
        end

        # Add correct quotes to the formatted string, preferring retaining the existing
        # quotes if possible.
        def quote(string, node)
          str_node = node.first_argument
          start_delimiter = str_node.loc.begin.source
          end_delimiter = str_node.loc.end.source

          # If there is any interpolation, the delimiters need to be changed potentially
          if node.each_descendant(:dstr, :dsym).any?
            case start_delimiter
            when "'"
              start_delimiter = end_delimiter = '"'
            when /\A%q(.)/
              start_delimiter = "%Q#{Regexp.last_match[1]}"
            end
          end

          "#{start_delimiter}#{string}#{end_delimiter}"
        end

        def argument_values(arguments)
          arguments.map { |argument| argument_value(argument) }
        end

        def argument_value(argument)
          argument = argument.children.first if argument.begin_type?

          if argument.dsym_type?
            dsym_value(argument)
          elsif argument.hash_type?
            hash_value(argument)
          elsif rational_number?(argument)
            rational_value(argument)
          elsif complex_number?(argument)
            complex_value(argument)
          elsif argument.respond_to?(:value)
            argument.value
          else
            argument.source
          end
        end

        def dsym_value(dsym_node)
          dsym_node.children.first.source
        end

        def hash_value(hash_node)
          hash_node.each_pair.with_object({}) do |pair, hash|
            hash[pair.key.value] = argument_value(pair.value)
          end
        end

        def rational_value(rational_node)
          rational_node.source.to_r
        end

        def complex_value(complex_node)
          Complex(complex_node.source)
        end
      end
    end
  end
end
