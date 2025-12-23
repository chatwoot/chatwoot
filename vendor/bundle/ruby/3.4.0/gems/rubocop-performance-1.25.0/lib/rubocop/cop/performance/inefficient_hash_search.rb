# frozen_string_literal: true

module RuboCop
  module Cop
    module Performance
      # Checks for inefficient searching of keys and values within
      # hashes.
      #
      # `Hash#keys.include?` is less efficient than `Hash#key?` because
      # the former allocates a new array and then performs an O(n) search
      # through that array, while `Hash#key?` does not allocate any array and
      # performs a faster O(1) search for the key.
      #
      # `Hash#values.include?` is less efficient than `Hash#value?`. While they
      # both perform an O(n) search through all of the values, calling `values`
      # allocates a new array while using `value?` does not.
      #
      # @safety
      #   This cop is unsafe because it can't tell whether the receiver is a hash object.
      #
      # @example
      #   # bad
      #   { a: 1, b: 2 }.keys.include?(:a)
      #   { a: 1, b: 2 }.keys.include?(:z)
      #   h = { a: 1, b: 2 }; h.keys.include?(100)
      #
      #   # good
      #   { a: 1, b: 2 }.key?(:a)
      #   { a: 1, b: 2 }.has_key?(:z)
      #   h = { a: 1, b: 2 }; h.key?(100)
      #
      #   # bad
      #   { a: 1, b: 2 }.values.include?(2)
      #   { a: 1, b: 2 }.values.include?('garbage')
      #   h = { a: 1, b: 2 }; h.values.include?(nil)
      #
      #   # good
      #   { a: 1, b: 2 }.value?(2)
      #   { a: 1, b: 2 }.has_value?('garbage')
      #   h = { a: 1, b: 2 }; h.value?(nil)
      #
      class InefficientHashSearch < Base
        extend AutoCorrector

        RESTRICT_ON_SEND = %i[include?].freeze

        def_node_matcher :inefficient_include?, <<~PATTERN
          (call (call $_ {:keys :values}) :include? _)
        PATTERN

        def on_send(node)
          inefficient_include?(node) do |receiver|
            return if receiver.nil?

            message = message(node)
            add_offense(node, message: message) do |corrector|
              # Replace `keys.include?` or `values.include?` with the appropriate
              # `key?`/`value?` method.
              corrector.replace(node, replacement(node))
            end
          end
        end
        alias on_csend on_send

        private

        def message(node)
          "Use `##{correct_method(node)}` instead of `##{current_method(node)}.include?`."
        end

        def replacement(node)
          "#{correct_hash_expression(node)}#{correct_dot(node)}#{correct_method(node)}(#{correct_argument(node)})"
        end

        def correct_method(node)
          case current_method(node)
          when :keys then use_long_method ? 'has_key?' : 'key?'
          when :values then use_long_method ? 'has_value?' : 'value?'
          end
        end

        def current_method(node)
          node.receiver.method_name
        end

        def use_long_method
          config.for_enabled_cop('Style/PreferredHashMethods')['EnforcedStyle'] == 'long'
        end

        def correct_argument(node)
          node.first_argument.source
        end

        def correct_hash_expression(node)
          node.receiver.receiver.source
        end

        def correct_dot(node)
          node.receiver.loc.dot.source
        end
      end
    end
  end
end
