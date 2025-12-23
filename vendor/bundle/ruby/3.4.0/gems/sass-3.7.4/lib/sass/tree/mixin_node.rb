require 'sass/tree/node'

module Sass::Tree
  # A static node representing a mixin include.
  # When in a static tree, the sole purpose is to wrap exceptions
  # to add the mixin to the backtrace.
  #
  # @see Sass::Tree
  class MixinNode < Node
    # The name of the mixin.
    # @return [String]
    attr_reader :name

    # The arguments to the mixin.
    # @return [Array<Script::Tree::Node>]
    attr_accessor :args

    # A hash from keyword argument names to values.
    # @return [Sass::Util::NormalizedMap<Script::Tree::Node>]
    attr_accessor :keywords

    # The first splat argument for this mixin, if one exists.
    #
    # This could be a list of positional arguments, a map of keyword
    # arguments, or an arglist containing both.
    #
    # @return [Node?]
    attr_accessor :splat

    # The second splat argument for this mixin, if one exists.
    #
    # If this exists, it's always a map of keyword arguments, and
    # \{#splat} is always either a list or an arglist.
    #
    # @return [Node?]
    attr_accessor :kwarg_splat

    # @param name [String] The name of the mixin
    # @param args [Array<Script::Tree::Node>] See \{#args}
    # @param splat [Script::Tree::Node] See \{#splat}
    # @param kwarg_splat [Script::Tree::Node] See \{#kwarg_splat}
    # @param keywords [Sass::Util::NormalizedMap<Script::Tree::Node>] See \{#keywords}
    def initialize(name, args, keywords, splat, kwarg_splat)
      @name = name
      @args = args
      @keywords = keywords
      @splat = splat
      @kwarg_splat = kwarg_splat
      super()
    end
  end
end
