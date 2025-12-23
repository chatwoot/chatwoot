# frozen_string_literal: true

module RuboCop
  module AST
    class NodePattern
      # Base class for AST Nodes of a `NodePattern`
      class Node < ::Parser::AST::Node
        extend SimpleForwardable
        include ::RuboCop::AST::Descendence

        MATCHES_WITHIN_SET = %i[symbol number string].to_set.freeze
        private_constant :MATCHES_WITHIN_SET

        ###
        # To be overridden by subclasses
        ###

        def rest?
          false
        end

        def capture?
          false
        end

        # @return [Integer, Range] An Integer for fixed length terms, otherwise a Range.
        # Note: `arity.end` may be `Float::INFINITY`
        def arity
          1
        end

        # @return [Array<Node>, nil] replace node with result, or `nil` if no change requested.
        def in_sequence_head
          nil
        end

        ###
        # Utilities
        ###

        # @return [Array<Node>]
        def children_nodes
          children.grep(Node)
        end

        # @return [Node] most nodes have only one child
        def child
          children[0]
        end

        # @return [Integer] nb of captures that this node will emit
        def nb_captures
          children_nodes.sum(&:nb_captures)
        end

        # @return [Boolean] returns whether it matches a variable number of elements
        def variadic?
          arity.is_a?(Range)
        end

        # @return [Boolean] returns true for nodes having a Ruby literal equivalent
        # that matches within a Set (e.g. `42`, `:sym` but not `/regexp/`)
        def matches_within_set?
          MATCHES_WITHIN_SET.include?(type)
        end

        # @return [Range] arity as a Range
        def arity_range
          a = arity
          a.is_a?(Range) ? a : INT_TO_RANGE[a]
        end

        def with(type: @type, children: @children, location: @location)
          self.class.new(type, children, { location: location })
        end

        def source_range
          loc.expression
        end

        INT_TO_RANGE = Hash.new { |h, k| h[k] = k..k }
        private_constant :INT_TO_RANGE

        # :nodoc:
        module ForbidInSeqHead
          def in_sequence_head
            raise NodePattern::Invalid, "A sequence can not start with a #{type}"
          end
        end

        ###
        # Subclasses for specific node types
        ###

        # Node class for `$something`
        class Capture < Node
          # Delegate most introspection methods to it's only child
          def_delegators :child, :arity, :rest?

          def capture?
            true
          end

          def nb_captures
            1 + super
          end

          def in_sequence_head
            wildcard, original_child = child.in_sequence_head
            return unless original_child

            [wildcard, self] # ($...) => (_ $...)
          end
        end

        # Node class for `(type first second ...)`
        class Sequence < Node
          include ForbidInSeqHead

          def initialize(type, children = [], properties = {})
            if (replace = children.first.in_sequence_head)
              children = [*replace, *children[1..]]
            end

            super
          end
        end

        # Node class for `predicate?(:arg, :list)`
        class Predicate < Node
          def method_name
            children.first
          end

          def arg_list
            children[1..]
          end
        end
        FunctionCall = Predicate

        # Node class for `int+`
        class Repetition < Node
          include ForbidInSeqHead

          def operator
            children[1]
          end

          ARITIES = {
            '*': 0..Float::INFINITY,
            '+': 1..Float::INFINITY,
            '?': 0..1
          }.freeze

          def arity
            ARITIES[operator]
          end
        end

        # Node class for `...`
        class Rest < Node
          ARITY = (0..Float::INFINITY).freeze
          private_constant :ARITY

          def rest?
            true
          end

          def arity
            ARITY
          end

          def in_sequence_head
            [Node.new(:wildcard), self]
          end
        end

        # Node class for `<int str ...>`
        class AnyOrder < Node
          include ForbidInSeqHead

          ARITIES = Hash.new { |h, k| h[k] = k - 1..Float::INFINITY }
          private_constant :ARITIES

          def term_nodes
            ends_with_rest? ? children[0...-1] : children
          end

          def ends_with_rest?
            children.last.rest?
          end

          def rest_node
            children.last if ends_with_rest?
          end

          def arity
            return children.size unless ends_with_rest?

            ARITIES[children.size]
          end
        end

        # A list (potentially empty) of nodes; part of a Union
        class Subsequence < Node
          include ForbidInSeqHead

          def arity
            min, max = children.map { |child| child.arity_range.minmax }.transpose.map(&:sum)
            min == max ? min || 0 : min..max # NOTE: || 0 for empty case, where min == max == nil.
          end

          def in_sequence_head
            super if children.empty?

            return unless (replace = children.first.in_sequence_head)

            [with(children: [*replace, *children[1..]])]
          end
        end

        # Node class for `{ ... }`
        class Union < Node
          def arity
            minima, maxima = children.map { |child| child.arity_range.minmax }.transpose
            min = minima.min
            max = maxima.max
            min == max ? min : min..max
          end

          def in_sequence_head
            return unless children.any?(&:in_sequence_head)

            new_children = children.map do |child|
              next child unless (replace = child.in_sequence_head)

              if replace.size > 1
                Subsequence.new(:subsequence, replace, loc: child.loc)
              else
                replace.first
              end
            end

            [with(children: new_children)]
          end

          # Each child in a union must contain the same number
          # of captures. Only one branch ends up capturing.
          def nb_captures
            child.nb_captures
          end
        end

        # Registry
        MAP = Hash.new(Node).merge!(
          sequence: Sequence,
          repetition: Repetition,
          rest: Rest,
          capture: Capture,
          predicate: Predicate,
          any_order: AnyOrder,
          function_call: FunctionCall,
          subsequence: Subsequence,
          union: Union
        ).freeze
      end
    end
  end
end
