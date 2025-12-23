module Sass::Script::Tree
  # A SassScript object representing `#{}` interpolation outside a string.
  #
  # @see StringInterpolation
  class Interpolation < Node
    # @return [Node] The SassScript before the interpolation
    attr_reader :before

    # @return [Node] The SassScript within the interpolation
    attr_reader :mid

    # @return [Node] The SassScript after the interpolation
    attr_reader :after

    # @return [Boolean] Whether there was whitespace between `before` and `#{`
    attr_reader :whitespace_before

    # @return [Boolean] Whether there was whitespace between `}` and `after`
    attr_reader :whitespace_after

    # @return [Boolean] Whether the original format of the interpolation was
    #   plain text, not an interpolation. This is used when converting back to
    #   SassScript.
    attr_reader :originally_text

    # @return [Boolean] Whether a color value passed to the interpolation should
    #   generate a warning.
    attr_reader :warn_for_color

    # The type of interpolation deprecation for this node.
    #
    # This can be `:none`, indicating that the node doesn't use deprecated
    # interpolation; `:immediate`, indicating that a deprecation warning should
    # be emitted as soon as possible; or `:potential`, indicating that a
    # deprecation warning should be emitted if the resulting string is used in a
    # way that would distinguish it from a list.
    #
    # @return [Symbol]
    attr_reader :deprecation

    # Interpolation in a property is of the form `before #{mid} after`.
    #
    # @param before [Node] See {Interpolation#before}
    # @param mid [Node] See {Interpolation#mid}
    # @param after [Node] See {Interpolation#after}
    # @param wb [Boolean] See {Interpolation#whitespace_before}
    # @param wa [Boolean] See {Interpolation#whitespace_after}
    # @param originally_text [Boolean] See {Interpolation#originally_text}
    # @param warn_for_color [Boolean] See {Interpolation#warn_for_color}
    def initialize(before, mid, after, wb, wa, opts = {})
      @before = before
      @mid = mid
      @after = after
      @whitespace_before = wb
      @whitespace_after = wa
      @originally_text = opts[:originally_text] || false
      @warn_for_color = opts[:warn_for_color] || false
      @deprecation = opts[:deprecation] || :none
    end

    # @return [String] A human-readable s-expression representation of the interpolation
    def inspect
      "(interpolation #{@before.inspect} #{@mid.inspect} #{@after.inspect})"
    end

    # @see Node#to_sass
    def to_sass(opts = {})
      return to_quoted_equivalent.to_sass if deprecation == :immediate

      res = ""
      res << @before.to_sass(opts) if @before
      res << ' ' if @before && @whitespace_before
      res << '#{' unless @originally_text
      res << @mid.to_sass(opts)
      res << '}' unless @originally_text
      res << ' ' if @after && @whitespace_after
      res << @after.to_sass(opts) if @after
      res
    end

    # Returns an `unquote()` expression that will evaluate to the same value as
    # this interpolation.
    #
    # @return [Sass::Script::Tree::Node]
    def to_quoted_equivalent
      Funcall.new(
        "unquote",
        [to_string_interpolation(self)],
        Sass::Util::NormalizedMap.new,
        nil,
        nil)
    end

    # Returns the three components of the interpolation, `before`, `mid`, and `after`.
    #
    # @return [Array<Node>]
    # @see #initialize
    # @see Node#children
    def children
      [@before, @mid, @after].compact
    end

    # @see Node#deep_copy
    def deep_copy
      node = dup
      node.instance_variable_set('@before', @before.deep_copy) if @before
      node.instance_variable_set('@mid', @mid.deep_copy)
      node.instance_variable_set('@after', @after.deep_copy) if @after
      node
    end

    protected

    # Converts a script node into a corresponding string interpolation
    # expression.
    #
    # @param node_or_interp [Sass::Script::Tree::Node]
    # @return [Sass::Script::Tree::StringInterpolation]
    def to_string_interpolation(node_or_interp)
      unless node_or_interp.is_a?(Interpolation)
        node = node_or_interp
        return string_literal(node.value.to_s) if node.is_a?(Literal)
        if node.is_a?(StringInterpolation)
          return concat(string_literal(node.quote), concat(node, string_literal(node.quote)))
        end
        return StringInterpolation.new(string_literal(""), node, string_literal(""))
      end

      interp = node_or_interp
      after_string_or_interp =
        if interp.after
          to_string_interpolation(interp.after)
        else
          string_literal("")
        end
      if interp.after && interp.whitespace_after
        after_string_or_interp = concat(string_literal(' '), after_string_or_interp)
      end

      mid_string_or_interp = to_string_interpolation(interp.mid)

      before_string_or_interp =
        if interp.before
          to_string_interpolation(interp.before)
        else
          string_literal("")
        end
      if interp.before && interp.whitespace_before
        before_string_or_interp = concat(before_string_or_interp, string_literal(' '))
      end

      concat(before_string_or_interp, concat(mid_string_or_interp, after_string_or_interp))
    end

    private

    # Evaluates the interpolation.
    #
    # @param environment [Sass::Environment] The environment in which to evaluate the SassScript
    # @return [Sass::Script::Value::String]
    #   The SassScript string that is the value of the interpolation
    def _perform(environment)
      res = ""
      res << @before.perform(environment).to_s if @before
      res << " " if @before && @whitespace_before

      val = @mid.perform(environment)
      if @warn_for_color && val.is_a?(Sass::Script::Value::Color) && val.name
        alternative = Operation.new(Sass::Script::Value::String.new("", :string), @mid, :plus)
        Sass::Util.sass_warn <<MESSAGE
WARNING on line #{line}, column #{source_range.start_pos.offset}#{" of #{filename}" if filename}:
You probably don't mean to use the color value `#{val}' in interpolation here.
It may end up represented as #{val.inspect}, which will likely produce invalid CSS.
Always quote color names when using them as strings (for example, "#{val}").
If you really want to use the color value here, use `#{alternative.to_sass}'.
MESSAGE
      end

      res << val.to_s(:quote => :none)
      res << " " if @after && @whitespace_after
      res << @after.perform(environment).to_s if @after
      str = Sass::Script::Value::String.new(
        res, :identifier,
        (to_quoted_equivalent.to_sass if deprecation == :potential))
      str.source_range = source_range
      opts(str)
    end

    # Concatenates two string literals or string interpolation expressions.
    #
    # @param string_or_interp1 [Sass::Script::Tree::Literal|Sass::Script::Tree::StringInterpolation]
    # @param string_or_interp2 [Sass::Script::Tree::Literal|Sass::Script::Tree::StringInterpolation]
    # @return [Sass::Script::Tree::StringInterpolation]
    def concat(string_or_interp1, string_or_interp2)
      if string_or_interp1.is_a?(Literal) && string_or_interp2.is_a?(Literal)
        return string_literal(string_or_interp1.value.value + string_or_interp2.value.value)
      end

      if string_or_interp1.is_a?(Literal)
        string = string_or_interp1
        interp = string_or_interp2
        before = string_literal(string.value.value + interp.before.value.value)
        return StringInterpolation.new(before, interp.mid, interp.after)
      end

      StringInterpolation.new(
        string_or_interp1.before,
        string_or_interp1.mid,
        concat(string_or_interp1.after, string_or_interp2))
    end

    # Returns a string literal with the given contents.
    #
    # @param string [String]
    # @return string [Sass::Script::Tree::Literal]
    def string_literal(string)
      Literal.new(Sass::Script::Value::String.new(string, :string))
    end
  end
end
