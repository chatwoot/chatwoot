# frozen_string_literal: true

module Parser
  module Source

    class Map::Operator < Map
      attr_reader :operator

      def initialize(operator, expression)
        @operator = operator

        super(expression)
      end
    end

  end
end
