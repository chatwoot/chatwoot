require 'sass/tree/node'

module Sass::Tree
  # A dynamic node representing a Sass `@for` loop.
  #
  # @see Sass::Tree
  class ForNode < Node
    # The name of the loop variable.
    # @return [String]
    attr_reader :var

    # The parse tree for the initial expression.
    # @return [Script::Tree::Node]
    attr_accessor :from

    # The parse tree for the final expression.
    # @return [Script::Tree::Node]
    attr_accessor :to

    # Whether to include `to` in the loop or stop just before.
    # @return [Boolean]
    attr_reader :exclusive

    # @param var [String] See \{#var}
    # @param from [Script::Tree::Node] See \{#from}
    # @param to [Script::Tree::Node] See \{#to}
    # @param exclusive [Boolean] See \{#exclusive}
    def initialize(var, from, to, exclusive)
      @var = var
      @from = from
      @to = to
      @exclusive = exclusive
      super()
    end
  end
end
