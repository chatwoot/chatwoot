# frozen_string_literal: true

module Parser
  module Source

    class Map::Constant < Map
      attr_reader :double_colon
      attr_reader :name
      attr_reader :operator

      def initialize(double_colon, name, expression)
        @double_colon, @name = double_colon, name

        super(expression)
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
