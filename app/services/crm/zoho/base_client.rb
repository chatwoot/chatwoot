# frozen_string_literal: true

module Crm
  module Zoho
    class BaseClient < Crm::BaseClient
      private

      def base_url
        # api_domain viene del response de token (específico por región/datacenter)
        # Ejemplos: https://www.zohoapis.com, https://www.zohoapis.eu, etc.
        @credentials['api_domain'] || 'https://www.zohoapis.com'
      end
    end
  end
end
