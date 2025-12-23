# frozen_string_literal: true

module RuboCop
  module Cop
    module Metrics
      module Utils
        # @api private
        #
        # Identifies repetitions `{c}send` calls with no arguments:
        #
        #   foo.bar
        #   foo.bar # => repeated
        #   foo.bar.baz.qux # => inner send repeated
        #   foo.bar.baz.other # => both inner send repeated
        #   foo.bar(2) # => not repeated
        #
        # It also invalidates sequences if a receiver is reassigned:
        #
        #   xx.foo.bar
        #   xx.foo.baz      # => inner send repeated
        #   self.xx = any   # => invalidates everything so far
        #   xx.foo.baz      # => no repetition
        #   self.xx.foo.baz # => all repeated
        #
        module RepeatedAttributeDiscount
          extend NodePattern::Macros
          include RuboCop::AST::Sexp

          VAR_SETTER_TO_GETTER = {
            lvasgn: :lvar,
            ivasgn: :ivar,
            cvasgn: :cvar,
            gvasgn: :gvar
          }.freeze

          # Plug into the calculator
          def initialize(node, discount_repeated_attributes: false)
            super(node)
            return unless discount_repeated_attributes

            self_attributes = {} # Share hash for `(send nil? :foo)` and `(send (self) :foo)`
            @known_attributes = { s(:self) => self_attributes, nil => self_attributes }
            # example after running `obj = foo.bar; obj.baz.qux`
            # { nil => {foo: {bar: {}}},
            #   s(self) => same hash ^,
            #   s(:lvar, :obj) => {baz: {qux: {}}}
            # }
          end

          def discount_repeated_attributes?
            defined?(@known_attributes)
          end

          def evaluate_branch_nodes(node)
            return if discount_repeated_attributes? && discount_repeated_attribute?(node)

            super
          end

          def calculate_node(node)
            update_repeated_attribute(node) if discount_repeated_attributes?
            super
          end

          private

          # @!method attribute_call?(node)
          def_node_matcher :attribute_call?, <<~PATTERN
            (call _receiver _method # and no parameters
            )
          PATTERN

          def discount_repeated_attribute?(send_node)
            return false unless attribute_call?(send_node)

            repeated = true
            find_attributes(send_node) do |hash, lookup|
              return false if hash.nil?

              repeated = false
              hash[lookup] = {}
            end

            repeated
          end

          def update_repeated_attribute(node)
            return unless (receiver, method = setter_to_getter(node))

            calls = find_attributes(receiver) { return }
            if method # e.g. `self.foo = 42`
              calls.delete(method)
            else      # e.g. `var = 42`
              calls.clear
            end
          end

          # @!method root_node?(node)
          def_node_matcher :root_node?, <<~PATTERN
            { nil? | self               # e.g. receiver of `my_method` or `self.my_attr`
            | lvar | ivar | cvar | gvar # e.g. receiver of `var.my_method`
            | const }                   # e.g. receiver of `MyConst.foo.bar`
          PATTERN

          # Returns the "known_attributes" for the `node` by walking the receiver tree
          # If at any step the subdirectory does not exist, it is yielded with the
          # associated key (method_name)
          # If the node is not a series of `(c)send` calls with no arguments,
          # then `nil` is yielded
          def find_attributes(node, &block)
            if attribute_call?(node)
              calls = find_attributes(node.receiver, &block)
              value = node.method_name
            elsif root_node?(node)
              calls = @known_attributes
              value = node
            else
              return yield nil
            end

            calls.fetch(value) { yield [calls, value] }
          end

          # @returns `[receiver, method | nil]` for the given setter `node`
          # or `nil` if it is not a setter.
          def setter_to_getter(node)
            if (type = VAR_SETTER_TO_GETTER[node.type])
              # (lvasgn :my_var (int 42)) => [(lvar my_var), nil]
              [s(type, node.children.first), nil]
            elsif node.shorthand_asgn? # (or-asgn (send _receiver :foo) _value)
              # (or-asgn (send _receiver :foo) _value) => [_receiver, :foo]
              node.children.first.children
            elsif node.respond_to?(:setter_method?) && node.setter_method?
              # (send _receiver :foo= (int 42) ) => [_receiver, :foo]
              method_name = node.method_name[0...-1].to_sym
              [node.receiver, method_name]
            end
          end
        end
      end
    end
  end
end
