# frozen_string_literal: true

module Parser
  module Source

    class Map::ObjcKwarg < Map
      attr_reader :keyword
      attr_reader :operator
      attr_reader :argument

      def initialize(keyword_l, operator_l, argument_l, expression_l)
        @keyword, @operator, @argument = keyword_l, operator_l, argument_l

        super(expression_l)
      end
    end

  end
end
