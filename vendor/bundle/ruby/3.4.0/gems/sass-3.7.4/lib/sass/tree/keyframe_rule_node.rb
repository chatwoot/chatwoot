module Sass::Tree
  class KeyframeRuleNode < Node
    # The text of the directive after any interpolated SassScript has been resolved.
    # Since this is only a static node, this is the only value property.
    #
    # @return [String]
    attr_accessor :resolved_value

    # @param resolved_value [String] See \{#resolved_value}
    def initialize(resolved_value)
      @resolved_value = resolved_value
      super()
    end
  end
end
