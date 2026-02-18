# YCloud CRM Contact management.
# Manage contacts within YCloud's built-in CRM for segmentation and campaigns.
# https://docs.ycloud.com/reference/contacts
module Whatsapp::Ycloud
  class ContactService
    pattr_initialize [:whatsapp_channel!]

    # Create a new contact in YCloud.
    # @param params [Hash]:
    #   - nickname [String] Contact name
    #   - countryCode [String] Country code (e.g., 'US')
    #   - phoneNumber [String] Phone number
    #   - email [String] Email address
    #   - tags [Array<String>] Tags for segmentation
    #   - customAttributes [Array<Hash>] Custom attribute values
    def create(params)
      client.post('/contacts', params)
    end

    # List contacts with pagination.
    # @param page [Integer] Page number
    # @param limit [Integer] Items per page
    # @param filter [Hash] Optional filter criteria
    def list(page: 1, limit: 20, **filter)
      client.get('/contacts', { page: page, limit: limit }.merge(filter))
    end

    # Retrieve a specific contact.
    def retrieve(contact_id)
      client.get("/contacts/#{contact_id}")
    end

    # Update a contact.
    def update(contact_id, params)
      client.patch("/contacts/#{contact_id}", params)
    end

    # Delete a contact.
    def delete(contact_id)
      client.delete("/contacts/#{contact_id}")
    end

    # List available custom contact attributes.
    def list_attributes
      client.get('/contact-attributes')
    end

    private

    def client
      @client ||= ApiClient.new(whatsapp_channel: whatsapp_channel)
    end
  end
end
