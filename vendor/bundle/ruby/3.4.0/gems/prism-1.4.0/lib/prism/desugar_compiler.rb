# frozen_string_literal: true

module Prism
  class DesugarAndWriteNode # :nodoc:
    include DSL

    attr_reader :node, :default_source, :read_class, :write_class, :arguments

    def initialize(node, default_source, read_class, write_class, **arguments)
      @node = node
      @default_source = default_source
      @read_class = read_class
      @write_class = write_class
      @arguments = arguments
    end

    # Desugar `x &&= y` to `x && x = y`
    def compile
      and_node(
        location: node.location,
        left: public_send(read_class, location: node.name_loc, **arguments),
        right: public_send(
          write_class,
          location: node.location,
          **arguments,
          name_loc: node.name_loc,
          value: node.value,
          operator_loc: node.operator_loc
        ),
        operator_loc: node.operator_loc
      )
    end
  end

  class DesugarOrWriteDefinedNode # :nodoc:
    include DSL

    attr_reader :node, :default_source, :read_class, :write_class, :arguments

    def initialize(node, default_source, read_class, write_class, **arguments)
      @node = node
      @default_source = default_source
      @read_class = read_class
      @write_class = write_class
      @arguments = arguments
    end

    # Desugar `x ||= y` to `defined?(x) ? x : x = y`
    def compile
      if_node(
        location: node.location,
        if_keyword_loc: node.operator_loc,
        predicate: defined_node(
          location: node.name_loc,
          value: public_send(read_class, location: node.name_loc, **arguments),
          keyword_loc: node.operator_loc
        ),
        then_keyword_loc: node.operator_loc,
        statements: statements_node(
          location: node.location,
          body: [public_send(read_class, location: node.name_loc, **arguments)]
        ),
        subsequent: else_node(
          location: node.location,
          else_keyword_loc: node.operator_loc,
          statements: statements_node(
            location: node.location,
            body: [
              public_send(
                write_class,
                location: node.location,
                **arguments,
                name_loc: node.name_loc,
                value: node.value,
                operator_loc: node.operator_loc
              )
            ]
          ),
          end_keyword_loc: node.operator_loc
        ),
        end_keyword_loc: node.operator_loc
      )
    end
  end

  class DesugarOperatorWriteNode # :nodoc:
    include DSL

    attr_reader :node, :default_source, :read_class, :write_class, :arguments

    def initialize(node, default_source, read_class, write_class, **arguments)
      @node = node
      @default_source = default_source
      @read_class = read_class
      @write_class = write_class
      @arguments = arguments
    end

    # Desugar `x += y` to `x = x + y`
    def compile
      binary_operator_loc = node.binary_operator_loc.chop

      public_send(
        write_class,
        location: node.location,
        **arguments,
        name_loc: node.name_loc,
        value: call_node(
          location: node.location,
          receiver: public_send(
            read_class,
            location: node.name_loc,
            **arguments
          ),
          name: binary_operator_loc.slice.to_sym,
          message_loc: binary_operator_loc,
          arguments: arguments_node(
            location: node.value.location,
            arguments: [node.value]
          )
        ),
        operator_loc: node.binary_operator_loc.copy(
          start_offset: node.binary_operator_loc.end_offset - 1,
          length: 1
        )
      )
    end
  end

  class DesugarOrWriteNode # :nodoc:
    include DSL

    attr_reader :node, :default_source, :read_class, :write_class, :arguments

    def initialize(node, default_source, read_class, write_class, **arguments)
      @node = node
      @default_source = default_source
      @read_class = read_class
      @write_class = write_class
      @arguments = arguments
    end

    # Desugar `x ||= y` to `x || x = y`
    def compile
      or_node(
        location: node.location,
        left: public_send(read_class, location: node.name_loc, **arguments),
        right: public_send(
          write_class,
          location: node.location,
          **arguments,
          name_loc: node.name_loc,
          value: node.value,
          operator_loc: node.operator_loc
        ),
        operator_loc: node.operator_loc
      )
    end
  end

  private_constant :DesugarAndWriteNode, :DesugarOrWriteNode, :DesugarOrWriteDefinedNode, :DesugarOperatorWriteNode

  class ClassVariableAndWriteNode
    def desugar # :nodoc:
      DesugarAndWriteNode.new(self, source, :class_variable_read_node, :class_variable_write_node, name: name).compile
    end
  end

  class ClassVariableOrWriteNode
    def desugar # :nodoc:
      DesugarOrWriteDefinedNode.new(self, source, :class_variable_read_node, :class_variable_write_node, name: name).compile
    end
  end

  class ClassVariableOperatorWriteNode
    def desugar # :nodoc:
      DesugarOperatorWriteNode.new(self, source, :class_variable_read_node, :class_variable_write_node, name: name).compile
    end
  end

  class ConstantAndWriteNode
    def desugar # :nodoc:
      DesugarAndWriteNode.new(self, source, :constant_read_node, :constant_write_node, name: name).compile
    end
  end

  class ConstantOrWriteNode
    def desugar # :nodoc:
      DesugarOrWriteDefinedNode.new(self, source, :constant_read_node, :constant_write_node, name: name).compile
    end
  end

  class ConstantOperatorWriteNode
    def desugar # :nodoc:
      DesugarOperatorWriteNode.new(self, source, :constant_read_node, :constant_write_node, name: name).compile
    end
  end

  class GlobalVariableAndWriteNode
    def desugar # :nodoc:
      DesugarAndWriteNode.new(self, source, :global_variable_read_node, :global_variable_write_node, name: name).compile
    end
  end

  class GlobalVariableOrWriteNode
    def desugar # :nodoc:
      DesugarOrWriteDefinedNode.new(self, source, :global_variable_read_node, :global_variable_write_node, name: name).compile
    end
  end

  class GlobalVariableOperatorWriteNode
    def desugar # :nodoc:
      DesugarOperatorWriteNode.new(self, source, :global_variable_read_node, :global_variable_write_node, name: name).compile
    end
  end

  class InstanceVariableAndWriteNode
    def desugar # :nodoc:
      DesugarAndWriteNode.new(self, source, :instance_variable_read_node, :instance_variable_write_node, name: name).compile
    end
  end

  class InstanceVariableOrWriteNode
    def desugar # :nodoc:
      DesugarOrWriteNode.new(self, source, :instance_variable_read_node, :instance_variable_write_node, name: name).compile
    end
  end

  class InstanceVariableOperatorWriteNode
    def desugar # :nodoc:
      DesugarOperatorWriteNode.new(self, source, :instance_variable_read_node, :instance_variable_write_node, name: name).compile
    end
  end

  class LocalVariableAndWriteNode
    def desugar # :nodoc:
      DesugarAndWriteNode.new(self, source, :local_variable_read_node, :local_variable_write_node, name: name, depth: depth).compile
    end
  end

  class LocalVariableOrWriteNode
    def desugar # :nodoc:
      DesugarOrWriteNode.new(self, source, :local_variable_read_node, :local_variable_write_node, name: name, depth: depth).compile
    end
  end

  class LocalVariableOperatorWriteNode
    def desugar # :nodoc:
      DesugarOperatorWriteNode.new(self, source, :local_variable_read_node, :local_variable_write_node, name: name, depth: depth).compile
    end
  end

  # DesugarCompiler is a compiler that desugars Ruby code into a more primitive
  # form. This is useful for consumers that want to deal with fewer node types.
  class DesugarCompiler < MutationCompiler
    # @@foo &&= bar
    #
    # becomes
    #
    # @@foo && @@foo = bar
    def visit_class_variable_and_write_node(node)
      node.desugar
    end

    # @@foo ||= bar
    #
    # becomes
    #
    # defined?(@@foo) ? @@foo : @@foo = bar
    def visit_class_variable_or_write_node(node)
      node.desugar
    end

    # @@foo += bar
    #
    # becomes
    #
    # @@foo = @@foo + bar
    def visit_class_variable_operator_write_node(node)
      node.desugar
    end

    # Foo &&= bar
    #
    # becomes
    #
    # Foo && Foo = bar
    def visit_constant_and_write_node(node)
      node.desugar
    end

    # Foo ||= bar
    #
    # becomes
    #
    # defined?(Foo) ? Foo : Foo = bar
    def visit_constant_or_write_node(node)
      node.desugar
    end

    # Foo += bar
    #
    # becomes
    #
    # Foo = Foo + bar
    def visit_constant_operator_write_node(node)
      node.desugar
    end

    # $foo &&= bar
    #
    # becomes
    #
    # $foo && $foo = bar
    def visit_global_variable_and_write_node(node)
      node.desugar
    end

    # $foo ||= bar
    #
    # becomes
    #
    # defined?($foo) ? $foo : $foo = bar
    def visit_global_variable_or_write_node(node)
      node.desugar
    end

    # $foo += bar
    #
    # becomes
    #
    # $foo = $foo + bar
    def visit_global_variable_operator_write_node(node)
      node.desugar
    end

    # @foo &&= bar
    #
    # becomes
    #
    # @foo && @foo = bar
    def visit_instance_variable_and_write_node(node)
      node.desugar
    end

    # @foo ||= bar
    #
    # becomes
    #
    # @foo || @foo = bar
    def visit_instance_variable_or_write_node(node)
      node.desugar
    end

    # @foo += bar
    #
    # becomes
    #
    # @foo = @foo + bar
    def visit_instance_variable_operator_write_node(node)
      node.desugar
    end

    # foo &&= bar
    #
    # becomes
    #
    # foo && foo = bar
    def visit_local_variable_and_write_node(node)
      node.desugar
    end

    # foo ||= bar
    #
    # becomes
    #
    # foo || foo = bar
    def visit_local_variable_or_write_node(node)
      node.desugar
    end

    # foo += bar
    #
    # becomes
    #
    # foo = foo + bar
    def visit_local_variable_operator_write_node(node)
      node.desugar
    end
  end
end
