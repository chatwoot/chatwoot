module Sass
  module Tree
    # A dynamic node representing a mixin definition.
    #
    # @see Sass::Tree
    class MixinDefNode < Node
      # The mixin name.
      # @return [String]
      attr_reader :name

      # The arguments for the mixin.
      # Each element is a tuple containing the variable for argument
      # and the parse tree for the default value of the argument.
      #
      # @return [Array<(Script::Tree::Node, Script::Tree::Node)>]
      attr_accessor :args

      # The splat argument for this mixin, if one exists.
      #
      # @return [Script::Tree::Node?]
      attr_accessor :splat

      # Whether the mixin uses `@content`. Set during the nesting check phase.
      # @return [Boolean]
      attr_accessor :has_content

      # @param name [String] The mixin name
      # @param args [Array<(Script::Tree::Node, Script::Tree::Node)>] See \{#args}
      # @param splat [Script::Tree::Node] See \{#splat}
      def initialize(name, args, splat)
        @name = name
        @args = args
        @splat = splat
        super()
      end
    end
  end
end
