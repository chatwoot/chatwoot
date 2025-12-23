module Sass
  module Tree
    # A dynamic node representing a Sass `@error` statement.
    #
    # @see Sass::Tree
    class ErrorNode < Node
      # The expression to print.
      # @return [Script::Tree::Node]
      attr_accessor :expr

      # @param expr [Script::Tree::Node] The expression to print
      def initialize(expr)
        @expr = expr
        super()
      end
    end
  end
end
