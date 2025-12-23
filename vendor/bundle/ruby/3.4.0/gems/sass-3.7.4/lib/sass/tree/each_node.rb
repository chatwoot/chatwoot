require 'sass/tree/node'

module Sass::Tree
  # A dynamic node representing a Sass `@each` loop.
  #
  # @see Sass::Tree
  class EachNode < Node
    # The names of the loop variables.
    # @return [Array<String>]
    attr_reader :vars

    # The parse tree for the list.
    # @return [Script::Tree::Node]
    attr_accessor :list

    # @param vars [Array<String>] The names of the loop variables
    # @param list [Script::Tree::Node] The parse tree for the list
    def initialize(vars, list)
      @vars = vars
      @list = list
      super()
    end
  end
end
