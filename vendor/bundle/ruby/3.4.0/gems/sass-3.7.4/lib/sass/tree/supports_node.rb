module Sass::Tree
  # A static node representing a `@supports` rule.
  #
  # @see Sass::Tree
  class SupportsNode < DirectiveNode
    # The name, which may include a browser prefix.
    #
    # @return [String]
    attr_accessor :name

    # The supports condition.
    #
    # @return [Sass::Supports::Condition]
    attr_accessor :condition

    # @param condition [Sass::Supports::Condition] See \{#condition}
    def initialize(name, condition)
      @name = name
      @condition = condition
      super('')
    end

    # @see DirectiveNode#value
    def value; raise NotImplementedError; end

    # @see DirectiveNode#resolved_value
    def resolved_value
      @resolved_value ||= "@#{name} #{condition.to_css}"
    end

    # True when the directive has no visible children.
    #
    # @return [Boolean]
    def invisible?
      children.all? {|c| c.invisible?}
    end
  end
end
