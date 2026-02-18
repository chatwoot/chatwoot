# frozen_string_literal: true

module Crm
  module Hubspot
    class BaseClient < Crm::BaseClient
      private

      def base_url
        'https://api.hubapi.com'
      end

      # HubSpot Private App tokens are long-lived and don't expire
      def ensure_valid_token!; end
    end
  end
end
