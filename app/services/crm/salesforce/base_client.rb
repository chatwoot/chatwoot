# frozen_string_literal: true

module Crm
  module Salesforce
    class BaseClient < Crm::BaseClient
      API_VERSION = 'v61.0'

      private

      def base_url
        # instance_url es dinámico por organización de Salesforce
        # Ejemplo: https://xxx-dev-ed.develop.my.salesforce.com
        "#{@credentials['instance_url']}/services/data/#{API_VERSION}"
      end
    end
  end
end
