# frozen_string_literal: true

module Crm
  module Salesforce
    module Api
      # Client for Salesforce Opportunity API
      class OpportunityClient < Crm::Salesforce::BaseClient
        # Create a new opportunity
        #
        # @param opportunity_data [Hash] Opportunity data
        # @return [Hash] Response with opportunity ID
        def create_opportunity(opportunity_data)
          request(:post, '/sobjects/Opportunity', body: opportunity_data.to_json)
        end

        # Update an existing opportunity
        #
        # @param opportunity_id [String] Salesforce Opportunity ID
        # @param opportunity_data [Hash] Opportunity data
        # @return [Hash] Response
        def update_opportunity(opportunity_id, opportunity_data)
          request(:patch, "/sobjects/Opportunity/#{opportunity_id}", body: opportunity_data.to_json)
        end

        # Get opportunity by ID
        #
        # @param opportunity_id [String] Salesforce Opportunity ID
        # @return [Hash] Opportunity data
        def get_opportunity(opportunity_id)
          request(:get, "/sobjects/Opportunity/#{opportunity_id}")
        end
      end
    end
  end
end
