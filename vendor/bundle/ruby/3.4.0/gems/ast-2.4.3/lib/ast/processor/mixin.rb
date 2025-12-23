module AST
  class Processor
    # The processor module is a module which helps transforming one
    # AST into another.  In a nutshell, the {#process} method accepts
    # a {Node} and dispatches it to a handler corresponding to its
    # type, and returns a (possibly) updated variant of the node.
    #
    # The processor module has a set of associated design patterns.
    # They are best explained with a concrete example. Let's define a
    # simple arithmetic language and an AST format for it:
    #
    # Terminals (AST nodes which do not have other AST nodes inside):
    #
    #   * `(integer <int-literal>)`,
    #
    # Nonterminals (AST nodes with other nodes as children):
    #
    #   * `(add <node> <node>)`,
    #   * `(multiply <node> <node>)`,
    #   * `(divide <node> <node>)`,
    #   * `(negate <node>)`,
    #   * `(store <node> <string-literal>)`: stores value of `<node>`
    #     into a variable named `<string-literal>`,
    #   * `(load <string-literal>)`: loads value of a variable named
    #     `<string-literal>`,
    #   * `(each <node> ...)`: computes each of the `<node>`s and
    #     prints the result.
    #
    # All AST nodes have the same Ruby class, and therefore they don't
    # know how to traverse themselves. (A solution which dynamically
    # checks the type of children is possible, but is slow and
    # error-prone.) So, a class including the module which knows how
    # to traverse the entire tree should be defined.  Such classes
    # have a handler for each nonterminal node which recursively
    # processes children nodes:
    #
    #     require 'ast'
    #
    #     class ArithmeticsProcessor
    #       include AST::Processor::Mixin
    #       # This method traverses any binary operators such as (add)
    #       # or (multiply).
    #       def process_binary_op(node)
    #         # Children aren't decomposed automatically; it is
    #         # suggested to use Ruby multiple assignment expansion,
    #         # as it is very convenient here.
    #         left_expr, right_expr = *node
    #
    #         # AST::Node#updated won't change node type if nil is
    #         # passed as a first argument, which allows to reuse the
    #         # same handler for multiple node types using `alias'
    #         # (below).
    #         node.updated(nil, [
    #           process(left_expr),
    #           process(right_expr)
    #         ])
    #       end
    #       alias_method :on_add,      :process_binary_op
    #       alias_method :on_multiply, :process_binary_op
    #       alias_method :on_divide,   :process_binary_op
    #
    #       def on_negate(node)
    #         # It is also possible to use #process_all for more
    #         # compact code if every child is a Node.
    #         node.updated(nil, process_all(node))
    #       end
    #
    #       def on_store(node)
    #         expr, variable_name = *node
    #
    #         # Note that variable_name is not a Node and thus isn't
    #         # passed to #process.
    #         node.updated(nil, [
    #           process(expr),
    #           variable_name
    #         ])
    #       end
    #
    #       # (load) is effectively a terminal node, and so it does
    #       # not need an explicit handler, as the following is the
    #       # default behavior.  Essentially, for any nodes that don't
    #       # have a defined handler, the node remains unchanged.
    #       def on_load(node)
    #         nil
    #       end
    #
    #       def on_each(node)
    #         node.updated(nil, process_all(node))
    #       end
    #     end
    #
    # Let's test our ArithmeticsProcessor:
    #
    #     include AST::Sexp
    #     expr = s(:add, s(:integer, 2), s(:integer, 2))
    #
    #     p ArithmeticsProcessor.new.process(expr) == expr # => true
    #
    # As expected, it does not change anything at all. This isn't
    # actually very useful, so let's now define a Calculator, which
    # will compute the expression values:
    #
    #     # This Processor folds nonterminal nodes and returns an
    #     # (integer) terminal node.
    #     class ArithmeticsCalculator < ArithmeticsProcessor
    #       def compute_op(node)
    #         # First, node children are processed and then unpacked
    #         # to local variables.
    #         nodes = process_all(node)
    #
    #         if nodes.all? { |node| node.type == :integer }
    #           # If each of those nodes represents a literal, we can
    #           # fold this node!
    #           values = nodes.map { |node| node.children.first }
    #           AST::Node.new(:integer, [
    #             yield(values)
    #           ])
    #         else
    #           # Otherwise, we can just leave the current node in the
    #           # tree and only update it with processed children
    #           # nodes, which can be partially folded.
    #           node.updated(nil, nodes)
    #         end
    #       end
    #
    #       def on_add(node)
    #         compute_op(node) { |left, right| left + right }
    #       end
    #
    #       def on_multiply(node)
    #         compute_op(node) { |left, right| left * right }
    #       end
    #     end
    #
    # Let's check:
    #
    #     p ArithmeticsCalculator.new.process(expr) # => (integer 4)
    #
    # Excellent, the calculator works! Now, a careful reader could
    # notice that the ArithmeticsCalculator does not know how to
    # divide numbers. What if we pass an expression with division to
    # it?
    #
    #     expr_with_division = \
    #       s(:add,
    #         s(:integer, 1),
    #         s(:divide,
    #           s(:add, s(:integer, 8), s(:integer, 4)),
    #           s(:integer, 3))) # 1 + (8 + 4) / 3
    #
    #     folded_expr_with_division = ArithmeticsCalculator.new.process(expr_with_division)
    #     p folded_expr_with_division
    #     # => (add
    #     #      (integer 1)
    #     #      (divide
    #     #        (integer 12)
    #     #        (integer 3)))
    #
    # As you can see, the expression was folded _partially_: the inner
    # `(add)` node which could be computed was folded to
    # `(integer 12)`, the `(divide)` node is left as-is because there
    # is no computing handler for it, and the root `(add)` node was
    # also left as it is because some of its children were not
    # literals.
    #
    # Note that this partial folding is only possible because the
    # _data_ format, i.e. the format in which the computed values of
    # the nodes are represented, is the same as the AST itself.
    #
    # Let's extend our ArithmeticsCalculator class further.
    #
    #     class ArithmeticsCalculator
    #       def on_divide(node)
    #         compute_op(node) { |left, right| left / right }
    #       end
    #
    #       def on_negate(node)
    #         # Note how #compute_op works regardless of the operator
    #         # arity.
    #         compute_op(node) { |value| -value }
    #       end
    #     end
    #
    # Now, let's apply our renewed ArithmeticsCalculator to a partial
    # result of previous evaluation:
    #
    #     p ArithmeticsCalculator.new.process(expr_with_division) # => (integer 5)
    #
    # Five! Excellent. This is also pretty much how CRuby 1.8 executed
    # its programs.
    #
    # Now, let's do some automated bug searching. Division by zero is
    # an error, right? So if we could detect that someone has divided
    # by zero before the program is even run, that could save some
    # debugging time.
    #
    #     class DivisionByZeroVerifier < ArithmeticsProcessor
    #       class VerificationFailure < Exception; end
    #
    #       def on_divide(node)
    #         # You need to process the children to handle nested divisions
    #         # such as:
    #         # (divide
    #         #   (integer 1)
    #         #   (divide (integer 1) (integer 0))
    #         left, right = process_all(node)
    #
    #         if right.type == :integer &&
    #            right.children.first == 0
    #           raise VerificationFailure, "Ouch! This code divides by zero."
    #         end
    #       end
    #
    #       def divides_by_zero?(ast)
    #         process(ast)
    #         false
    #       rescue VerificationFailure
    #         true
    #       end
    #     end
    #
    #     nice_expr = \
    #       s(:divide,
    #         s(:add, s(:integer, 10), s(:integer, 2)),
    #         s(:integer, 4))
    #
    #     p DivisionByZeroVerifier.new.divides_by_zero?(nice_expr)
    #     # => false. Good.
    #
    #     bad_expr = \
    #       s(:add, s(:integer, 10),
    #         s(:divide, s(:integer, 1), s(:integer, 0)))
    #
    #     p DivisionByZeroVerifier.new.divides_by_zero?(bad_expr)
    #     # => true. WHOOPS. DO NOT RUN THIS.
    #
    # Of course, this won't detect more complex cases... unless you
    # use some partial evaluation before! The possibilites are
    # endless. Have fun.
    module Mixin
      # Dispatches `node`. If a node has type `:foo`, then a handler
      # named `on_foo` is invoked with one argument, the `node`; if
      # there isn't such a handler, {#handler_missing} is invoked
      # with the same argument.
      #
      # If the handler returns `nil`, `node` is returned; otherwise,
      # the return value of the handler is passed along.
      #
      # @param  [AST::Node, nil] node
      # @return [AST::Node, nil]
      def process(node)
        return if node.nil?

        node = node.to_ast

        # Invoke a specific handler
        on_handler = :"on_#{node.type}"
        if respond_to? on_handler
          new_node = send on_handler, node
        else
          new_node = handler_missing(node)
        end

        node = new_node if new_node

        node
      end

      # {#process}es each node from `nodes` and returns an array of
      # results.
      #
      # @param  [Array<AST::Node>] nodes
      # @return [Array<AST::Node>]
      def process_all(nodes)
        nodes.to_a.map do |node|
          process node
        end
      end

      # Default handler. Does nothing.
      #
      # @param  [AST::Node] node
      # @return [AST::Node, nil]
      def handler_missing(node)
      end
    end
  end
end
