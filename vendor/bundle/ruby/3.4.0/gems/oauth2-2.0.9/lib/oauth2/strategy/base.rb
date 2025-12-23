# frozen_string_literal: true

module OAuth2
  module Strategy
    class Base
      def initialize(client)
        @client = client
      end
    end
  end
end
