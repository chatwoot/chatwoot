module Sass
  module Tree
    # A dynamic node representing returning from a function.
    #
    # @see Sass::Tree
    class ReturnNode < Node
      # The expression to return.
      #
      # @return [Script::Tree::Node]
      attr_accessor :expr

      # @param expr [Script::Tree::Node] The expression to return
      def initialize(expr)
        @expr = expr
        super()
      end
    end
  end
end
