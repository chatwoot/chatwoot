module Sass::Script::Tree
  # A SassScript object representing `#{}` interpolation within a string.
  #
  # @see Interpolation
  class StringInterpolation < Node
    # @return [Literal] The string literal before this interpolation.
    attr_reader :before

    # @return [Node] The SassScript within the interpolation
    attr_reader :mid

    # @return [StringInterpolation, Literal]
    #     The string literal or string interpolation before this interpolation.
    attr_reader :after

    # Whether this is a CSS string or a CSS identifier. The difference is that
    # strings are written with double-quotes, while identifiers aren't.
    #
    # String interpolations are only ever identifiers if they're quote-like
    # functions such as `url()`.
    #
    # @return [Symbol] `:string` or `:identifier`
    def type
      @before.value.type
    end

    # Returns the quote character that should be used to wrap a Sass
    # representation of this interpolation.
    def quote
      quote_for(self) || '"'
    end

    # Interpolation in a string is of the form `"before #{mid} after"`,
    # where `before` and `after` may include more interpolation.
    #
    # @param before [StringInterpolation, Literal] See {StringInterpolation#before}
    # @param mid [Node] See {StringInterpolation#mid}
    # @param after [Literal] See {StringInterpolation#after}
    def initialize(before, mid, after)
      @before = before
      @mid = mid
      @after = after
    end

    # @return [String] A human-readable s-expression representation of the interpolation
    def inspect
      "(string_interpolation #{@before.inspect} #{@mid.inspect} #{@after.inspect})"
    end

    # @see Node#to_sass
    def to_sass(opts = {})
      quote = type == :string ? opts[:quote] || quote_for(self) || '"' : :none
      opts = opts.merge(:quote => quote)

      res = ""
      res << quote if quote != :none
      res << _to_sass(before, opts)
      res << '#{' << @mid.to_sass(opts.merge(:quote => nil)) << '}'
      res << _to_sass(after, opts)
      res << quote if quote != :none
      res
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

    # Evaluates the interpolation.
    #
    # @param environment [Sass::Environment] The environment in which to evaluate the SassScript
    # @return [Sass::Script::Value::String]
    #   The SassScript string that is the value of the interpolation
    def _perform(environment)
      res = ""
      before = @before.perform(environment)
      res << before.value
      mid = @mid.perform(environment)
      res << (mid.is_a?(Sass::Script::Value::String) ? mid.value : mid.to_s(:quote => :none))
      res << @after.perform(environment).value
      opts(Sass::Script::Value::String.new(res, before.type))
    end

    private

    def _to_sass(string_or_interp, opts)
      result = string_or_interp.to_sass(opts)
      opts[:quote] == :none ? result : result.slice(1...-1)
    end

    def quote_for(string_or_interp)
      if string_or_interp.is_a?(Sass::Script::Tree::Literal)
        return nil if string_or_interp.value.value.empty?
        return '"' if string_or_interp.value.value.include?("'")
        return "'" if string_or_interp.value.value.include?('"')
        return nil
      end

      # Double-quotes take precedence over single quotes.
      before_quote = quote_for(string_or_interp.before)
      return '"' if before_quote == '"'
      after_quote = quote_for(string_or_interp.after)
      return '"' if after_quote == '"'

      # Returns "'" if either or both insist on single quotes, and nil
      # otherwise.
      before_quote || after_quote
    end
  end
end
