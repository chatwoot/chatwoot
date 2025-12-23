# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Warns the usage of unsafe number conversions. Unsafe
      # number conversion can cause unexpected error if auto type conversion
      # fails. Cop prefer parsing with number class instead.
      #
      # Conversion with `Integer`, `Float`, etc. will raise an `ArgumentError`
      # if given input that is not numeric (eg. an empty string), whereas
      # `to_i`, etc. will try to convert regardless of input (``''.to_i => 0``).
      # As such, this cop is disabled by default because it's not necessarily
      # always correct to raise if a value is not numeric.
      #
      # NOTE: Some values cannot be converted properly using one of the `Kernel`
      # method (for instance, `Time` and `DateTime` values are allowed by this
      # cop by default). Similarly, Rails' duration methods do not work well
      # with `Integer()` and can be allowed with `AllowedMethods`. By default,
      # there are no methods to allowed.
      #
      # @safety
      #   Autocorrection is unsafe because it is not guaranteed that the
      #   replacement `Kernel` methods are able to properly handle the
      #   input if it is not a standard class.
      #
      # @example
      #
      #   # bad
      #
      #   '10'.to_i
      #   '10.2'.to_f
      #   '10'.to_c
      #   '1/3'.to_r
      #   ['1', '2', '3'].map(&:to_i)
      #   foo.try(:to_f)
      #   bar.send(:to_c)
      #
      #   # good
      #
      #   Integer('10', 10)
      #   Float('10.2')
      #   Complex('10')
      #   Rational('1/3')
      #   ['1', '2', '3'].map { |i| Integer(i, 10) }
      #   foo.try { |i| Float(i) }
      #   bar.send { |i| Complex(i) }
      #
      # @example AllowedMethods: [] (default)
      #
      #   # bad
      #   10.minutes.to_i
      #
      # @example AllowedMethods: [minutes]
      #
      #   # good
      #   10.minutes.to_i
      #
      # @example AllowedPatterns: [] (default)
      #
      #   # bad
      #   10.minutes.to_i
      #
      # @example AllowedPatterns: ['min*']
      #
      #   # good
      #   10.minutes.to_i
      #
      # @example IgnoredClasses: [Time, DateTime] (default)
      #
      #   # good
      #   Time.now.to_datetime.to_i
      class NumberConversion < Base
        extend AutoCorrector
        include AllowedMethods
        include AllowedPattern

        CONVERSION_METHOD_CLASS_MAPPING = {
          to_i: "#{Integer.name}(%<number_object>s, 10)",
          to_f: "#{Float.name}(%<number_object>s)",
          to_c: "#{Complex.name}(%<number_object>s)",
          to_r: "#{Rational.name}(%<number_object>s)"
        }.freeze
        MSG = 'Replace unsafe number conversion with number ' \
              'class parsing, instead of using ' \
              '`%<current>s`, use stricter ' \
              '`%<corrected_method>s`.'
        CONVERSION_METHODS = %i[Integer Float Complex Rational to_i to_f to_c to_r].freeze
        METHODS = CONVERSION_METHOD_CLASS_MAPPING.keys.map(&:inspect).join(' ')

        # @!method to_method(node)
        def_node_matcher :to_method, <<~PATTERN
          (call $_ ${#{METHODS}})
        PATTERN

        # @!method to_method_symbol(node)
        def_node_matcher :to_method_symbol, <<~PATTERN
          (call _ $_ ${
            {
              (sym ${#{METHODS}})
              (block_pass (sym ${#{METHODS}}))
            }
          } ...)
        PATTERN

        def on_send(node)
          handle_conversion_method(node)
          handle_as_symbol(node)
        end
        alias on_csend on_send

        private

        def handle_conversion_method(node)
          to_method(node) do |receiver, to_method|
            next if receiver.nil? || allow_receiver?(receiver)

            message = format(
              MSG,
              current: "#{receiver.source}.#{to_method}",
              corrected_method: correct_method(node, receiver)
            )
            add_offense(node, message: message) do |corrector|
              next if part_of_ignored_node?(node)

              corrector.replace(node, correct_method(node, node.receiver))

              ignore_node(node)
            end
          end
        end

        def handle_as_symbol(node)
          to_method_symbol(node) do |receiver, sym_node, to_method|
            next if receiver.nil? || !node.arguments.one?

            message = format(
              MSG,
              current: sym_node.source,
              corrected_method: correct_sym_method(to_method)
            )
            add_offense(node, message: message) do |corrector|
              remove_parentheses(corrector, node) if node.parenthesized?

              corrector.replace(sym_node, correct_sym_method(to_method))
            end
          end
        end

        def correct_method(node, receiver)
          format(CONVERSION_METHOD_CLASS_MAPPING[node.method_name], number_object: receiver.source)
        end

        def correct_sym_method(to_method)
          body = format(CONVERSION_METHOD_CLASS_MAPPING[to_method], number_object: 'i')
          "{ |i| #{body} }"
        end

        def remove_parentheses(corrector, node)
          corrector.replace(node.loc.begin, ' ')
          corrector.remove(node.loc.end)
        end

        def allow_receiver?(receiver)
          if receiver.numeric_type? || (receiver.send_type? &&
            (conversion_method?(receiver.method_name) ||
            allowed_method_name?(receiver.method_name)))
            true
          elsif (receiver = top_receiver(receiver))
            receiver.const_type? && ignored_class?(receiver.const_name)
          else
            false
          end
        end

        def allowed_method_name?(name)
          allowed_method?(name) || matches_allowed_pattern?(name)
        end

        def top_receiver(node)
          receiver = node
          receiver = receiver.receiver until receiver.receiver.nil?
          receiver
        end

        def conversion_method?(method_name)
          CONVERSION_METHODS.include?(method_name)
        end

        def ignored_classes
          cop_config.fetch('IgnoredClasses', [])
        end

        def ignored_class?(name)
          ignored_classes.include?(name.to_s)
        end
      end
    end
  end
end
