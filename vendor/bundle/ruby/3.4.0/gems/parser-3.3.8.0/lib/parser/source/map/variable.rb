# frozen_string_literal: true

module Parser
  module Source

    class Map::Variable < Map
      attr_reader :name
      attr_reader :operator

      def initialize(name_l, expression_l=name_l)
        @name = name_l

        super(expression_l)
      end

      ##
      # @api private
      #
      def with_operator(operator_l)
        with { |map| map.update_operator(operator_l) }
      end

      protected

      def update_operator(operator_l)
        @operator = operator_l
      end
    end

  end
end
