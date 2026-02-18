# frozen_string_literal: true

module Crm
  module Salesforce
    module Api
      # Client for Salesforce Lead API
      class LeadClient < Crm::Salesforce::BaseClient
        # Create a new lead
        #
        # @param lead_data [Hash] Lead data
        # @return [Hash] Response with lead ID
        def create_lead(lead_data)
          request(:post, '/sobjects/Lead', body: lead_data.to_json)
        end

        # Update an existing lead
        #
        # @param lead_id [String] Salesforce Lead ID
        # @param lead_data [Hash] Lead data
        # @return [Hash] Response
        def update_lead(lead_id, lead_data)
          request(:patch, "/sobjects/Lead/#{lead_id}", body: lead_data.to_json)
        end

        # Get lead by ID
        #
        # @param lead_id [String] Salesforce Lead ID
        # @return [Hash] Lead data
        def get_lead(lead_id)
          request(:get, "/sobjects/Lead/#{lead_id}")
        end

        # Search leads by email
        #
        # @param email [String] Email to search
        # @return [Hash] Search results
        def search_by_email(email)
          escaped = email.to_s.gsub("'", "''")
          query = "SELECT Id, FirstName, LastName, Email, Company FROM Lead WHERE Email = '#{escaped}'"
          request(:get, '/query', query: { q: query })
        end

        # Add note to lead (using ContentNote object)
        #
        # @param lead_id [String] Salesforce Lead ID
        # @param title [String] Note title
        # @param content [String] Note content
        # @return [Hash] Response
        def add_note(lead_id, title, content)
          # Step 1: Create ContentNote
          note_response = request(:post, '/sobjects/ContentNote', body: {
            Title: title,
            Content: Base64.strict_encode64(content)
          }.to_json)

          return note_response unless note_response['id']

          # Step 2: Link ContentNote to Lead via ContentDocumentLink
          link_response = request(:post, '/sobjects/ContentDocumentLink', body: {
            ContentDocumentId: note_response['id'],
            LinkedEntityId: lead_id,
            ShareType: 'V', # Viewer permission
            Visibility: 'AllUsers'
          }.to_json)

          note_response
        end
      end
    end
  end
end
