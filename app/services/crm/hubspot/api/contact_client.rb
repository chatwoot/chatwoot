# frozen_string_literal: true

module Crm
  module Hubspot
    module Api
      class ContactClient < Crm::Hubspot::BaseClient
        # Create a new contact. Returns parsed response on success,
        # or { 'duplicate' => true, 'id' => '...' } when HubSpot returns 409.
        def create_contact(contact_data)
          request(:post, '/crm/v3/objects/contacts', body: contact_data.to_json)
        rescue Crm::BaseClient::ApiError => e
          # 409: "Contact already exists. Existing ID: 166076029334"
          if e.message.include?('409') && (match = e.message.match(/Existing ID:\s*(\d+)/))
            { 'duplicate' => true, 'id' => match[1] }
          else
            raise
          end
        end

        # Update an existing contact
        def update_contact(contact_id, contact_data)
          request(:patch, "/crm/v3/objects/contacts/#{contact_id}", body: contact_data.to_json)
        end

        # Search contacts by email using filterGroups
        def search_by_email(email)
          payload = {
            filterGroups: [{
              filters: [{ propertyName: 'email', operator: 'EQ', value: email }]
            }],
            properties: %w[firstname lastname email phone company],
            limit: 1
          }
          request(:post, '/crm/v3/objects/contacts/search', body: payload.to_json)
        end

        # Search contacts by WhatsApp phone number
        def search_by_phone(phone)
          payload = {
            filterGroups: [{
              filters: [{ propertyName: 'hs_whatsapp_phone_number', operator: 'EQ', value: phone }]
            }],
            properties: %w[firstname lastname email phone company hs_whatsapp_phone_number],
            limit: 1
          }
          request(:post, '/crm/v3/objects/contacts/search', body: payload.to_json)
        end

        # Get contact by HubSpot ID
        def get_contact(contact_id)
          request(:get, "/crm/v3/objects/contacts/#{contact_id}", query: {
            properties: 'firstname,lastname,email,phone,company,hs_lead_status'
          })
        end
      end
    end
  end
end
