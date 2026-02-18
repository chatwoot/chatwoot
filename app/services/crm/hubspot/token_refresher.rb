# frozen_string_literal: true

module Crm
  module Hubspot
    # HubSpot Private App tokens are long-lived and don't need refreshing.
    class TokenRefresher
      def initialize(hook)
        @hook = hook
      end

      def refresh!
        @hook.credentials
      end
    end
  end
end
