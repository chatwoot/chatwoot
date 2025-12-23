# frozen_string_literal: true

module Parser
  module Source

    class Map::Heredoc < Map
      attr_reader :heredoc_body
      attr_reader :heredoc_end

      def initialize(begin_l, body_l, end_l)
        @heredoc_body = body_l
        @heredoc_end  = end_l

        super(begin_l)
      end
    end

  end
end
