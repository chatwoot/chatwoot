# frozen_string_literal: true

module Crm
  module Salesforce
    module Mappers
      # Maps Nauto Console data to Salesforce Opportunity format
      class OpportunityMapper
        # Map to Salesforce Opportunity format
        #
        # @param params [Hash] Opportunity parameters
        # @return [Hash] Salesforce Opportunity data
        def self.map_opportunity(name:, close_date:, stage_name: 'Prospecting', amount: nil, description: nil, contact_id: nil, account_id: nil)
          {
            Name: name,
            CloseDate: close_date,
            StageName: stage_name, # Prospecting, Qualification, Needs Analysis, Value Proposition, etc.
            Amount: amount&.to_f,
            Description: description,
            AccountId: account_id,
            # Note: Salesforce Opportunities don't have a direct Contact field
            # Contact roles are managed separately via OpportunityContactRole
            Type: 'New Customer',
            LeadSource: 'Nauto Console'
          }.compact
        end
      end
    end
  end
end
