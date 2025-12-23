module Sass::Tree
  # A static node representing a CSS property.
  #
  # @see Sass::Tree
  class PropNode < Node
    # The name of the property,
    # interspersed with {Sass::Script::Tree::Node}s
    # representing `#{}`-interpolation.
    # Any adjacent strings will be merged together.
    #
    # @return [Array<String, Sass::Script::Tree::Node>]
    attr_accessor :name

    # The name of the property
    # after any interpolated SassScript has been resolved.
    # Only set once \{Tree::Visitors::Perform} has been run.
    #
    # @return [String]
    attr_accessor :resolved_name

    # The value of the property.
    #
    # For most properties, this will just contain a single Node. However, for
    # CSS variables, it will contain multiple strings and nodes representing
    # interpolation. Any adjacent strings will be merged together.
    #
    # @return [Array<String, Sass::Script::Tree::Node>]
    attr_accessor :value

    # The value of the property
    # after any interpolated SassScript has been resolved.
    # Only set once \{Tree::Visitors::Perform} has been run.
    #
    # @return [String]
    attr_accessor :resolved_value

    # How deep this property is indented
    # relative to a normal property.
    # This is only greater than 0 in the case that:
    #
    # * This node is in a CSS tree
    # * The style is :nested
    # * This is a child property of another property
    # * The parent property has a value, and thus will be rendered
    #
    # @return [Integer]
    attr_accessor :tabs

    # The source range in which the property name appears.
    #
    # @return [Sass::Source::Range]
    attr_accessor :name_source_range

    # The source range in which the property value appears.
    #
    # @return [Sass::Source::Range]
    attr_accessor :value_source_range

    # Whether this represents a CSS custom property.
    #
    # @return [Boolean]
    def custom_property?
      name.first.is_a?(String) && name.first.start_with?("--")
    end

    # @param name [Array<String, Sass::Script::Tree::Node>] See \{#name}
    # @param value [Array<String, Sass::Script::Tree::Node>] See \{#value}
    # @param prop_syntax [Symbol] `:new` if this property uses `a: b`-style syntax,
    #   `:old` if it uses `:a b`-style syntax
    def initialize(name, value, prop_syntax)
      @name = Sass::Util.strip_string_array(
        Sass::Util.merge_adjacent_strings(name))
      @value = Sass::Util.merge_adjacent_strings(value)
      @value = Sass::Util.strip_string_array(@value) unless custom_property?
      @tabs = 0
      @prop_syntax = prop_syntax
      super()
    end

    # Compares the names and values of two properties.
    #
    # @param other [Object] The object to compare with
    # @return [Boolean] Whether or not this node and the other object
    #   are the same
    def ==(other)
      self.class == other.class && name == other.name && value == other.value && super
    end

    # Returns a appropriate message indicating how to escape pseudo-class selectors.
    # This only applies for old-style properties with no value,
    # so returns the empty string if this is new-style.
    #
    # @return [String] The message
    def pseudo_class_selector_message
      if @prop_syntax == :new ||
          custom_property? ||
          !value.first.is_a?(Sass::Script::Tree::Literal) ||
          !value.first.value.is_a?(Sass::Script::Value::String) ||
          !value.first.value.value.empty?
        return ""
      end

      "\nIf #{declaration.dump} should be a selector, use \"\\#{declaration}\" instead."
    end

    # Computes the Sass or SCSS code for the variable declaration.
    # This is like \{#to\_scss} or \{#to\_sass},
    # except it doesn't print any child properties or a trailing semicolon.
    #
    # @param opts [{Symbol => Object}] The options hash for the tree.
    # @param fmt [Symbol] `:scss` or `:sass`.
    def declaration(opts = {:old => @prop_syntax == :old}, fmt = :sass)
      name = self.name.map {|n| n.is_a?(String) ? n : n.to_sass(opts)}.join
      value = self.value.map {|n| n.is_a?(String) ? n : n.to_sass(opts)}.join
      value = "(#{value})" if value_needs_parens?

      if name[0] == ?:
        raise Sass::SyntaxError.new("The \"#{name}: #{value}\"" +
                                    " hack is not allowed in the Sass indented syntax")
      end

      # The indented syntax doesn't support newlines in custom property values,
      # but we can losslessly convert them to spaces instead.
      value = value.tr("\n", " ") if fmt == :sass

      old = opts[:old] && fmt == :sass
      "#{old ? ':' : ''}#{name}#{old ? '' : ':'}#{custom_property? ? '' : ' '}#{value}".rstrip
    end

    # A property node is invisible if its value is empty.
    #
    # @return [Boolean]
    def invisible?
      !custom_property? && resolved_value.empty?
    end

    private

    # Returns whether \{#value} neesd parentheses in order to be parsed
    # properly as division.
    def value_needs_parens?
      return false if custom_property?

      root = value.first
      root.is_a?(Sass::Script::Tree::Operation) &&
        root.operator == :div &&
        root.operand1.is_a?(Sass::Script::Tree::Literal) &&
        root.operand1.value.is_a?(Sass::Script::Value::Number) &&
        root.operand1.value.original.nil? &&
        root.operand2.is_a?(Sass::Script::Tree::Literal) &&
        root.operand2.value.is_a?(Sass::Script::Value::Number) &&
        root.operand2.value.original.nil?
    end

    def check!
      return unless @options[:property_syntax] && @options[:property_syntax] != @prop_syntax
      raise Sass::SyntaxError.new(
        "Illegal property syntax: can't use #{@prop_syntax} syntax when " +
        ":property_syntax => #{@options[:property_syntax].inspect} is set.")
    end
  end
end
