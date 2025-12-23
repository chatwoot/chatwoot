module Sass::Script::Tree
  # The abstract superclass for SassScript parse tree nodes.
  #
  # Use \{#perform} to evaluate a parse tree.
  class Node
    # The options hash for this node.
    #
    # @return [{Symbol => Object}]
    attr_reader :options

    # The line of the document on which this node appeared.
    #
    # @return [Integer]
    attr_accessor :line

    # The source range in the document on which this node appeared.
    #
    # @return [Sass::Source::Range]
    attr_accessor :source_range

    # The file name of the document on which this node appeared.
    #
    # @return [String]
    attr_accessor :filename

    # Sets the options hash for this node,
    # as well as for all child nodes.
    # See {file:SASS_REFERENCE.md#Options the Sass options documentation}.
    #
    # @param options [{Symbol => Object}] The options
    def options=(options)
      @options = options
      children.each do |c|
        if c.is_a? Hash
          c.values.each {|v| v.options = options}
        else
          c.options = options
        end
      end
    end

    # Evaluates the node.
    #
    # \{#perform} shouldn't be overridden directly;
    # instead, override \{#\_perform}.
    #
    # @param environment [Sass::Environment] The environment in which to evaluate the SassScript
    # @return [Sass::Script::Value] The SassScript object that is the value of the SassScript
    def perform(environment)
      _perform(environment)
    rescue Sass::SyntaxError => e
      e.modify_backtrace(:line => line)
      raise e
    end

    # Returns all child nodes of this node.
    #
    # @return [Array<Node>]
    def children
      Sass::Util.abstract(self)
    end

    # Returns the text of this SassScript expression.
    #
    # @options opts :quote [String]
    #   The preferred quote style for quoted strings. If `:none`, strings are
    #   always emitted unquoted.
    #
    # @return [String]
    def to_sass(opts = {})
      Sass::Util.abstract(self)
    end

    # Returns a deep clone of this node.
    # The child nodes are cloned, but options are not.
    #
    # @return [Node]
    def deep_copy
      Sass::Util.abstract(self)
    end

    # Forces any division operations with number literals in this expression to
    # do real division, rather than returning strings.
    def force_division!
      children.each {|c| c.force_division!}
    end

    protected

    # Converts underscores to dashes if the :dasherize option is set.
    def dasherize(s, opts)
      if opts[:dasherize]
        s.tr('_', '-')
      else
        s
      end
    end

    # Evaluates this node.
    # Note that all {Sass::Script::Value} objects created within this method
    # should have their \{#options} attribute set, probably via \{#opts}.
    #
    # @param environment [Sass::Environment] The environment in which to evaluate the SassScript
    # @return [Sass::Script::Value] The SassScript object that is the value of the SassScript
    # @see #perform
    def _perform(environment)
      Sass::Util.abstract(self)
    end

    # Sets the \{#options} field on the given value and returns it.
    #
    # @param value [Sass::Script::Value]
    # @return [Sass::Script::Value]
    def opts(value)
      value.options = options
      value
    end
  end
end
