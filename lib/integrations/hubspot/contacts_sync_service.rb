class Integrations::Hubspot::ContactsSyncService
  include HTTParty
  base_uri 'https://api.hubapi.com'

  def initialize(access_token)
    Rails.logger.info "HubSpot Integration: Initializing contacts service with access token"
    @headers = {
      'Authorization' => "Bearer #{access_token}",
      'Content-Type' => 'application/json',
      'Accept' => 'application/json'
    }
  end

  def sync_contact(contact)
    Rails.logger.info "HubSpot Integration: Starting contact sync for contact #{contact.id}"
    Rails.logger.info "HubSpot Integration: Contact details - email: #{contact.email}, name: #{contact.name}, phone: #{contact.phone_number}"
    return nil unless should_sync_contact?(contact)
    create_or_update_contact(contact)
  end

  private

  def should_sync_contact?(contact)
    # Skip if it's an anonymous visitor
    return false if contact.contact_type == "visitor"
    
    true
  end

  def create_or_update_contact(contact)
    Rails.logger.info "HubSpot Integration: Starting contact sync for contact #{contact.id}"
    Rails.logger.info "HubSpot Integration: Contact details - email: #{contact.email}, name: #{contact.name}, phone: #{contact.phone_number}"
    
    properties = {
      email: contact.email,
      firstname: contact.name.split(' ').first,
      lastname: contact.name.split(' ').last || '',
      phone: contact.phone_number,
      company: contact.additional_attributes['company']
    }
    Rails.logger.info "HubSpot Integration: Contact properties: #{properties.inspect}"

    # First try to find existing contact
    response = self.class.post(
      "/crm/v3/objects/contacts/search",
      headers: @headers,
      body: {
        filterGroups: [{
          filters: [{
            propertyName: "email",
            operator: "EQ",
            value: contact.email
          }]
        }],
        properties: ["email", "firstname", "lastname"],
        limit: 100
      }.to_json
    )

    if response.success? && response.parsed_response['results'].any?
      contact_id = response.parsed_response['results'].first['id']
      Rails.logger.info "HubSpot Integration: Found existing contact with ID: #{contact_id}"
      
      # Update existing contact
      response = self.class.patch(
        "/crm/v3/objects/contacts/#{contact_id}",
        headers: @headers,
        body: { properties: properties }.to_json
      )
    else
      # Create new contact
      Rails.logger.info "HubSpot Integration: Creating new contact"
      response = self.class.post(
        "/crm/v3/objects/contacts",
        headers: @headers,
        body: { properties: properties }.to_json
      )
    end

    if response.success?
      Rails.logger.info "HubSpot Integration: Contact API response: #{response.parsed_response.inspect}"
      return response.parsed_response
    elsif response.code == 409
      # Extract contact ID from error message
      error_message = response.parsed_response['message']
      if error_message =~ /Existing ID: (\d+)/
        contact_id = $1
        Rails.logger.info "HubSpot Integration: Found existing contact ID from error: #{contact_id}"
        
        # Get the contact details with required properties
        get_response = self.class.get(
          "/crm/v3/objects/contacts/#{contact_id}",
          headers: @headers,
          query: { properties: ['email', 'firstname', 'lastname', 'phone', 'company'].join(',') }
        )
        
        if get_response.success?
          # Update the existing contact
          update_response = self.class.patch(
            "/crm/v3/objects/contacts/#{contact_id}",
            headers: @headers,
            body: { properties: properties }.to_json
          )
          
          if update_response.success?
            Rails.logger.info "HubSpot Integration: Updated existing contact: #{update_response.parsed_response.inspect}"
            return update_response.parsed_response
          end
          
          Rails.logger.info "HubSpot Integration: Retrieved existing contact: #{get_response.parsed_response.inspect}"
          return get_response.parsed_response
        else
          Rails.logger.error "HubSpot Integration: Failed to get contact details: #{get_response.code} - #{get_response.parsed_response.inspect}"
          return nil
        end
      end
    end
    
    Rails.logger.error "HubSpot Integration: Contact API error: #{response.code} - #{response.parsed_response.inspect}"
    Rails.logger.error "HubSpot Integration: Request body: #{properties.to_json}"
    return nil
  end
end 