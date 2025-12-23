require 'sass/tree/node'

module Sass::Tree
  # A static node representing an `@extend` directive.
  #
  # @see Sass::Tree
  class ExtendNode < Node
    # The parsed selector after interpolation has been resolved.
    # Only set once {Tree::Visitors::Perform} has been run.
    #
    # @return [Selector::CommaSequence]
    attr_accessor :resolved_selector

    # The CSS selector to extend, interspersed with {Sass::Script::Tree::Node}s
    # representing `#{}`-interpolation.
    #
    # @return [Array<String, Sass::Script::Tree::Node>]
    attr_accessor :selector

    # The extended selector source range.
    #
    # @return [Sass::Source::Range]
    attr_accessor :selector_source_range

    # Whether the `@extend` is allowed to match no selectors or not.
    #
    # @return [Boolean]
    def optional?; @optional; end

    # @param selector [Array<String, Sass::Script::Tree::Node>]
    #   The CSS selector to extend,
    #   interspersed with {Sass::Script::Tree::Node}s
    #   representing `#{}`-interpolation.
    # @param optional [Boolean] See \{ExtendNode#optional?}
    # @param selector_source_range [Sass::Source::Range] The extended selector source range.
    def initialize(selector, optional, selector_source_range)
      @selector = selector
      @optional = optional
      @selector_source_range = selector_source_range
      super()
    end
  end
end
