module Sass
  module Tree
    # A dynamic node representing a variable definition.
    #
    # @see Sass::Tree
    class VariableNode < Node
      # The name of the variable.
      # @return [String]
      attr_reader :name

      # The parse tree for the variable value.
      # @return [Script::Tree::Node]
      attr_accessor :expr

      # Whether this is a guarded variable assignment (`!default`).
      # @return [Boolean]
      attr_reader :guarded

      # Whether this is a global variable assignment (`!global`).
      # @return [Boolean]
      attr_reader :global

      # @param name [String] The name of the variable
      # @param expr [Script::Tree::Node] See \{#expr}
      # @param guarded [Boolean] See \{#guarded}
      # @param global [Boolean] See \{#global}
      def initialize(name, expr, guarded, global)
        @name = name
        @expr = expr
        @guarded = guarded
        @global = global
        super()
      end
    end
  end
end
