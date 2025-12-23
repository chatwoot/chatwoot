# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for redundant uses of `to_s`, `to_sym`, `to_i`, `to_f`, `to_d`, `to_r`, `to_c`,
      # `to_a`, `to_h`, and `to_set`.
      #
      # When one of these methods is called on an object of the same type, that object
      # is returned, making the call unnecessary. The cop detects conversion methods called
      # on object literals, class constructors, class `[]` methods, and the `Kernel` methods
      # `String()`, `Integer()`, `Float()`, BigDecimal(), `Rational()`, `Complex()`, and `Array()`.
      #
      # Specifically, these cases are detected for each conversion method:
      #
      # * `to_s` when called on a string literal, interpolated string, heredoc,
      #   or with `String.new` or `String()`.
      # * `to_sym` when called on a symbol literal or interpolated symbol.
      # * `to_i` when called on an integer literal or with `Integer()`.
      # * `to_f` when called on a float literal of with `Float()`.
      # * `to_r` when called on a rational literal or with `Rational()`.
      # * `to_c` when called on a complex literal of with `Complex()`.
      # * `to_a` when called on an array literal, or with `Array.new`, `Array()` or `Array[]`.
      # * `to_h` when called on a hash literal, or with `Hash.new`, `Hash()` or `Hash[]`.
      # * `to_set` when called on `Set.new` or `Set[]`.
      #
      # In all cases, chaining one same `to_*` conversion methods listed above is redundant.
      #
      # The cop can also register an offense for chaining conversion methods on methods that are
      # expected to return a specific type regardless of receiver (eg. `foo.inspect.to_s` and
      # `foo.to_json.to_s`).
      #
      # @example
      #   # bad
      #   "text".to_s
      #   :sym.to_sym
      #   42.to_i
      #   8.5.to_f
      #   12r.to_r
      #   1i.to_c
      #   [].to_a
      #   {}.to_h
      #   Set.new.to_set
      #
      #   # good
      #   "text"
      #   :sym
      #   42
      #   8.5
      #   12r
      #   1i
      #   []
      #   {}
      #   Set.new
      #
      #   # bad
      #   Integer(var).to_i
      #
      #   # good
      #   Integer(var)
      #
      #   # good - chaining to a type constructor with exceptions suppressed
      #   # in this case, `Integer()` could return `nil`
      #   Integer(var, exception: false).to_i
      #
      #   # bad - chaining the same conversion
      #   foo.to_s.to_s
      #
      #   # good
      #   foo.to_s
      #
      #   # bad - chaining a conversion to a method that is expected to return the same type
      #   foo.inspect.to_s
      #   foo.to_json.to_s
      #
      #   # good
      #   foo.inspect
      #   foo.to_json
      #
      class RedundantTypeConversion < Base
        extend AutoCorrector

        MSG = 'Redundant `%<method>s` detected.'

        # Maps conversion methods to the node types for the literals of that type
        LITERAL_NODE_TYPES = {
          to_s: %i[str dstr],
          to_sym: %i[sym dsym],
          to_i: %i[int],
          to_f: %i[float],
          to_r: %i[rational],
          to_c: %i[complex],
          to_a: %i[array],
          to_h: %i[hash],
          to_set: [] # sets don't have a literal or node type
        }.freeze

        # Maps each conversion method to the pattern matcher for that type's constructors
        # Not every type has a constructor, for instance Symbol.
        CONSTRUCTOR_MAPPING = {
          to_s: 'string_constructor?',
          to_i: 'integer_constructor?',
          to_f: 'float_constructor?',
          to_d: 'bigdecimal_constructor?',
          to_r: 'rational_constructor?',
          to_c: 'complex_constructor?',
          to_a: 'array_constructor?',
          to_h: 'hash_constructor?',
          to_set: 'set_constructor?'
        }.freeze

        # Methods that already are expected to return a given type, which makes a further
        # conversion redundant.
        TYPED_METHODS = { to_s: %i[inspect to_json] }.freeze

        CONVERSION_METHODS = Set[*LITERAL_NODE_TYPES.keys].freeze
        RESTRICT_ON_SEND = CONVERSION_METHODS + [:to_d]

        private_constant :LITERAL_NODE_TYPES, :CONSTRUCTOR_MAPPING

        # @!method type_constructor?(node, type_symbol)
        def_node_matcher :type_constructor?, <<~PATTERN
          (send {nil? (const {cbase nil?} :Kernel)} %1 ...)
        PATTERN

        # @!method string_constructor?(node)
        def_node_matcher :string_constructor?, <<~PATTERN
          {
            (send (const {cbase nil?} :String) :new ...)
            #type_constructor?(:String)
          }
        PATTERN

        # @!method integer_constructor?(node)
        def_node_matcher :integer_constructor?, <<~PATTERN
          #type_constructor?(:Integer)
        PATTERN

        # @!method float_constructor?(node)
        def_node_matcher :float_constructor?, <<~PATTERN
          #type_constructor?(:Float)
        PATTERN

        # @!method bigdecimal_constructor?(node)
        def_node_matcher :bigdecimal_constructor?, <<~PATTERN
          #type_constructor?(:BigDecimal)
        PATTERN

        # @!method rational_constructor?(node)
        def_node_matcher :rational_constructor?, <<~PATTERN
          #type_constructor?(:Rational)
        PATTERN

        # @!method complex_constructor?(node)
        def_node_matcher :complex_constructor?, <<~PATTERN
          #type_constructor?(:Complex)
        PATTERN

        # @!method array_constructor?(node)
        def_node_matcher :array_constructor?, <<~PATTERN
          {
            (send (const {cbase nil?} :Array) {:new :[]} ...)
            #type_constructor?(:Array)
          }
        PATTERN

        # @!method hash_constructor?(node)
        def_node_matcher :hash_constructor?, <<~PATTERN
          {
            (block (send (const {cbase nil?} :Hash) :new) ...)
            (send (const {cbase nil?} :Hash) {:new :[]} ...)
            (send {nil? (const {cbase nil?} :Kernel)} :Hash ...)
          }
        PATTERN

        # @!method set_constructor?(node)
        def_node_matcher :set_constructor?, <<~PATTERN
          {
            (send (const {cbase nil?} :Set) {:new :[]} ...)
          }
        PATTERN

        # @!method exception_false_keyword_argument?(node)
        def_node_matcher :exception_false_keyword_argument?, <<~PATTERN
          (hash (pair (sym :exception) false))
        PATTERN

        # rubocop:disable Metrics/AbcSize
        def on_send(node)
          return if hash_or_set_with_block?(node)

          receiver = find_receiver(node)
          return unless literal_receiver?(node, receiver) ||
                        constructor?(node, receiver) ||
                        chained_conversion?(node, receiver) ||
                        chained_to_typed_method?(node, receiver)

          message = format(MSG, method: node.method_name)

          add_offense(node.loc.selector, message: message) do |corrector|
            corrector.remove(node.loc.dot.join(node.loc.selector))
          end
        end
        # rubocop:enable Metrics/AbcSize
        alias on_csend on_send

        private

        def hash_or_set_with_block?(node)
          return false if !node.method?(:to_h) && !node.method?(:to_set)

          node.parent&.any_block_type? || node.last_argument&.block_pass_type?
        end

        def find_receiver(node)
          receiver = node.receiver
          return unless receiver

          while receiver.begin_type?
            break unless receiver.children.one?

            receiver = receiver.children.first
          end

          receiver
        end

        def literal_receiver?(node, receiver)
          return false unless receiver

          receiver.type?(*LITERAL_NODE_TYPES[node.method_name])
        end

        def constructor?(node, receiver)
          matcher = CONSTRUCTOR_MAPPING[node.method_name]
          return false unless matcher

          public_send(matcher, receiver) && !constructor_suppresses_exceptions?(receiver)
        end

        def constructor_suppresses_exceptions?(receiver)
          # If the constructor suppresses exceptions with `exception: false`, it is possible
          # it could return `nil`, and therefore a chained conversion is not redundant.
          receiver.arguments.any? { |arg| exception_false_keyword_argument?(arg) }
        end

        def chained_conversion?(node, receiver)
          return false unless receiver&.call_type?

          receiver.method?(node.method_name)
        end

        def chained_to_typed_method?(node, receiver)
          return false unless receiver&.call_type?

          TYPED_METHODS.fetch(node.method_name, []).include?(receiver.method_name)
        end
      end
    end
  end
end
