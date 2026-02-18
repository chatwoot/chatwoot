# frozen_string_literal: true

module Crm
  module Zoho
    module Api
      # Client for Zoho CRM Lead and Contact operations
      class LeadClient < Crm::Zoho::BaseClient
        API_PATH = '/crm/v8'

        # ============================================================================
        # LEAD OPERATIONS
        # ============================================================================

        # Create a new lead in Zoho CRM
        #
        # @param lead_data [Hash] Lead data
        # @option lead_data [String] :First_Name
        # @option lead_data [String] :Last_Name
        # @option lead_data [String] :Company
        # @option lead_data [String] :Email
        # @option lead_data [String] :Phone
        # @option lead_data [String] :State
        # @return [Hash] API response
        def create_lead(lead_data)
          request(:post, "#{API_PATH}/Leads", body: { data: [lead_data] }.to_json)
        end

        # Update an existing lead
        #
        # @param lead_id [String] Zoho lead ID
        # @param lead_data [Hash] Updated lead data
        # @return [Hash] API response
        def update_lead(lead_id, lead_data)
          data_with_id = lead_data.merge(id: lead_id)
          request(:put, "#{API_PATH}/Leads", body: { data: [data_with_id] }.to_json)
        end

        # Search for leads by criteria
        #
        # @param criteria [String] Search criteria (email, phone, etc.)
        # @return [Hash] API response
        def search_leads(criteria)
          request(:get, "#{API_PATH}/Leads/search", query: { criteria: criteria })
        end

        # Get lead by ID
        #
        # @param lead_id [String] Zoho lead ID
        # @return [Hash] API response
        def get_lead(lead_id)
          request(:get, "#{API_PATH}/Leads/#{lead_id}")
        end

        # ============================================================================
        # CONTACT OPERATIONS
        # ============================================================================

        # Create a new contact in Zoho CRM
        #
        # @param contact_data [Hash] Contact data
        # @option contact_data [String] :First_Name
        # @option contact_data [String] :Last_Name
        # @option contact_data [String] :Email
        # @option contact_data [String] :Phone
        # @option contact_data [String] :Mobile
        # @option contact_data [Hash] :Owner Owner object with :id
        # @return [Hash] API response
        def create_contact(contact_data)
          request(:post, "#{API_PATH}/Contacts", body: { data: [contact_data] }.to_json)
        end

        # Update an existing contact
        #
        # @param contact_id [String] Zoho contact ID
        # @param contact_data [Hash] Updated contact data
        # @return [Hash] API response
        def update_contact(contact_id, contact_data)
          data_with_id = contact_data.merge(id: contact_id)
          request(:put, "#{API_PATH}/Contacts", body: { data: [data_with_id] }.to_json)
        end

        # Search for contacts by criteria
        #
        # @param criteria [String] Search criteria (email, phone, etc.)
        # @return [Hash] API response
        def search_contacts(criteria)
          request(:get, "#{API_PATH}/Contacts/search", query: { criteria: criteria })
        end

        # Get contact by ID
        #
        # @param contact_id [String] Zoho contact ID
        # @return [Hash] API response
        def get_contact(contact_id)
          request(:get, "#{API_PATH}/Contacts/#{contact_id}")
        end

        # ============================================================================
        # NOTES OPERATIONS
        # ============================================================================

        # Add note to a lead or contact
        #
        # @param parent_id [String] Parent record ID (Lead or Contact)
        # @param note_title [String] Note title
        # @param note_content [String] Note content
        # @param se_module [String] Module name ('Leads' or 'Contacts')
        # @return [Hash] API response
        def add_note(parent_id, note_title, note_content, se_module: 'Leads')
          note_data = {
            Parent_Id: {
              id: parent_id
            },
            Note_Title: note_title,
            Note_Content: note_content,
            se_module: se_module
          }

          request(:post, "#{API_PATH}/Notes", body: { data: [note_data] }.to_json)
        end

        # ============================================================================
        # TAG OPERATIONS
        # ============================================================================

        # Add tags to a specific record
        #
        # @param record_id [String] Record ID to tag
        # @param tag_names [Array<String>] Tag names
        # @param module_name [String] Module name ('Leads', 'Contacts', etc.)
        # @return [Hash] API response
        def add_tags(record_id, tag_names, module_name: 'Leads')
          request(
            :post,
            "#{API_PATH}/#{module_name}/#{record_id}/actions/add_tags",
            body: { tags: tag_names.map { |name| { name: name } } }.to_json
          )
        end

        # Remove tags from records
        #
        # @param record_ids [Array<String>] Record IDs
        # @param tag_names [Array<String>] Tag names
        # @param module_name [String] Module name ('Leads', 'Contacts', etc.)
        # @return [Hash] API response
        def remove_tags(record_ids, tag_names, module_name: 'Leads')
          request(
            :post,
            "#{API_PATH}/#{module_name}/actions/remove_tags",
            body: { tags: tag_names.map { |name| { name: name } }, ids: record_ids }.to_json
          )
        end
      end
    end
  end
end
