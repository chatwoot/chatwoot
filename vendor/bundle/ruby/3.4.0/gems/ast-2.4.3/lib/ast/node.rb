# frozen_string_literal: true

module AST
  # Node is an immutable class, instances of which represent abstract
  # syntax tree nodes. It combines semantic information (i.e. anything
  # that affects the algorithmic properties of a program) with
  # meta-information (line numbers or compiler intermediates).
  #
  # Notes on inheritance
  # ====================
  #
  # The distinction between semantics and metadata is important. Complete
  # semantic information should be contained within just the {#type} and
  # {#children} of a Node instance; in other words, if an AST was to be
  # stripped of all meta-information, it should remain a valid AST which
  # could be successfully processed to yield a result with the same
  # algorithmic properties.
  #
  # Thus, Node should never be inherited in order to define methods which
  # affect or return semantic information, such as getters for `class_name`,
  # `superclass` and `body` in the case of a hypothetical `ClassNode`. The
  # correct solution is to use a generic Node with a {#type} of `:class`
  # and three children. See also {Processor} for tips on working with such
  # ASTs.
  #
  # On the other hand, Node can and should be inherited to define
  # application-specific metadata (see also {#initialize}) or customize the
  # printing format. It is expected that an application would have one or two
  # such classes and use them across the entire codebase.
  #
  # The rationale for this pattern is extensibility and maintainability.
  # Unlike static ones, dynamic languages do not require the presence of a
  # predefined, rigid structure, nor does it improve dispatch efficiency,
  # and while such a structure can certainly be defined, it does not add
  # any value but incurs a maintaining cost.
  # For example, extending the AST even with a transformation-local
  # temporary node type requires making globally visible changes to
  # the codebase.
  #
  class Node
    # Returns the type of this node.
    # @return [Symbol]
    attr_reader :type

    # Returns the children of this node.
    # The returned value is frozen.
    # The to_a alias is useful for decomposing nodes concisely.
    # For example:
    #
    #     node = s(:gasgn, :$foo, s(:integer, 1))
    #     var_name, value = *node
    #     p var_name # => :$foo
    #     p value    # => (integer 1)
    #
    # @return [Array]
    attr_reader :children
    alias to_a children

    # Returns the precomputed hash value for this node
    # @return [Integer]
    attr_reader :hash

    # Constructs a new instance of Node.
    #
    # The arguments `type` and `children` are converted with `to_sym` and
    # `to_a` respectively. Additionally, the result of converting `children`
    # is frozen. While mutating the arguments is generally considered harmful,
    # the most common case is to pass an array literal to the constructor. If
    # your code does not expect the argument to be frozen, use `#dup`.
    #
    # The `properties` hash is passed to {#assign_properties}.
    def initialize(type, children=[], properties={})
      @type, @children = type.to_sym, children.to_a.freeze

      assign_properties(properties)

      @hash = [@type, @children, self.class].hash

      freeze
    end

    # Test if other object is equal to
    # @param [Object] other
    # @return [Boolean]
    def eql?(other)
      self.class.eql?(other.class)   &&
      @type.eql?(other.type)         &&
      @children.eql?(other.children)
    end

    # By default, each entry in the `properties` hash is assigned to
    # an instance variable in this instance of Node. A subclass should define
    # attribute readers for such variables. The values passed in the hash
    # are not frozen or whitelisted; such behavior can also be implemented
    # by subclassing Node and overriding this method.
    #
    # @return [nil]
    def assign_properties(properties)
      properties.each do |name, value|
        instance_variable_set :"@#{name}", value
      end

      nil
    end
    protected :assign_properties

    alias   :original_dup :dup
    private :original_dup

    # Nodes are already frozen, so there is no harm in returning the
    # current node as opposed to initializing from scratch and freezing
    # another one.
    #
    # @return self
    def dup
      self
    end
    alias :clone :dup

    # Returns a new instance of Node where non-nil arguments replace the
    # corresponding fields of `self`.
    #
    # For example, `Node.new(:foo, [ 1, 2 ]).updated(:bar)` would yield
    # `(bar 1 2)`, and `Node.new(:foo, [ 1, 2 ]).updated(nil, [])` would
    # yield `(foo)`.
    #
    # If the resulting node would be identical to `self`, does nothing.
    #
    # @param  [Symbol, nil] type
    # @param  [Array, nil]  children
    # @param  [Hash, nil]   properties
    # @return [AST::Node]
    def updated(type=nil, children=nil, properties=nil)
      new_type       = type       || @type
      new_children   = children   || @children
      new_properties = properties || {}

      if @type == new_type &&
          @children == new_children &&
          properties.nil?
        self
      else
        copy = original_dup
        copy.send :initialize, new_type, new_children, new_properties
        copy
      end
    end

    # Compares `self` to `other`, possibly converting with `to_ast`. Only
    # `type` and `children` are compared; metadata is deliberately ignored.
    #
    # @return [Boolean]
    def ==(other)
      if equal?(other)
        true
      elsif other.respond_to? :to_ast
        other = other.to_ast
        other.type == self.type &&
          other.children == self.children
      else
        false
      end
    end

    # Concatenates `array` with `children` and returns the resulting node.
    #
    # @return [AST::Node]
    def concat(array)
      updated(nil, @children + array.to_a)
    end

    alias + concat

    # Appends `element` to `children` and returns the resulting node.
    #
    # @return [AST::Node]
    def append(element)
      updated(nil, @children + [element])
    end

    alias << append

    # Converts `self` to a pretty-printed s-expression.
    #
    # @param  [Integer] indent Base indentation level.
    # @return [String]
    def to_sexp(indent=0)
      indented = "  " * indent
      sexp = "#{indented}(#{fancy_type}"

      children.each do |child|
        if child.is_a?(Node)
          sexp += "\n#{child.to_sexp(indent + 1)}"
        else
          sexp += " #{child.inspect}"
        end
      end

      sexp += ")"

      sexp
    end

    alias to_s to_sexp

    # Converts `self` to a s-expression ruby string.
    # The code return will recreate the node, using the sexp module s()
    #
    # @param  [Integer] indent Base indentation level.
    # @return [String]
    def inspect(indent=0)
      indented = "  " * indent
      sexp = "#{indented}s(:#{@type}"

      children.each do |child|
        if child.is_a?(Node)
          sexp += ",\n#{child.inspect(indent + 1)}"
        else
          sexp += ", #{child.inspect}"
        end
      end

      sexp += ")"

      sexp
    end

    # @return [AST::Node] self
    def to_ast
      self
    end

    # Converts `self` to an Array where the first element is the type as a Symbol,
    # and subsequent elements are the same representation of its children.
    #
    # @return [Array<Symbol, [...Array]>]
    def to_sexp_array
      children_sexp_arrs = children.map do |child|
        if child.is_a?(Node)
          child.to_sexp_array
        else
          child
        end
      end

      [type, *children_sexp_arrs]
    end

    # Enables matching for Node, where type is the first element
    # and the children are remaining items.
    #
    # @return [Array]
    def deconstruct
      [type, *children]
    end

    protected

    # Returns `@type` with all underscores replaced by dashes. This allows
    # to write symbol literals without quotes in Ruby sources and yet have
    # nicely looking s-expressions.
    #
    # @return [String]
    def fancy_type
      @type.to_s.gsub('_', '-')
    end
  end
end
