class Integrations::Hubspot::InboxSyncService
  include HTTParty
  base_uri 'https://api.hubapi.com'

  def initialize(access_token, inbox)
    Rails.logger.info "HubSpot Integration: Initializing service with access token"
    @headers = {
      'Authorization' => "Bearer #{access_token}",
      'Content-Type' => 'application/json',
      'Accept' => 'application/json'
    }
    @inbox = inbox
    @contacts_service = Integrations::Hubspot::ContactsSyncService.new(access_token)
  end

  def sync_contact(contact)
    Rails.logger.info "HubSpot Integration: Starting contact sync for contact #{contact.id}"
    @contacts_service.sync_contact(contact)
  end

  private

  def get_or_create_dash_assist_inbox
    Rails.logger.info "HubSpot Integration: Fetching DashAssist inbox"
    endpoint = "/conversations/v3/inboxes"
    
    response = self.class.get(
      endpoint,
      headers: @headers
    )

    if response.success?
      Rails.logger.info "HubSpot Integration: Inboxes API response: #{response.parsed_response.inspect}"
      # Find DashAssist inbox
      inbox = response.parsed_response['results'].find { |i| i['name'] == 'dash_assist' }
      if inbox
        Rails.logger.info "HubSpot Integration: Found existing DashAssist inbox: #{inbox.inspect}"
        return inbox['id']
      end
      
      Rails.logger.info "HubSpot Integration: DashAssist inbox not found, attempting to create"
      # Create a new DashAssist inbox if none exists
      create_inbox_response = self.class.post(
        endpoint,
        headers: @headers,
        body: {
          name: 'dash_assist',
          type: 'CHAT'
        }.to_json
      )
      
      if create_inbox_response.success?
        Rails.logger.info "HubSpot Integration: Inbox created successfully: #{create_inbox_response.parsed_response.inspect}"
        return create_inbox_response.parsed_response['id']
      else
        Rails.logger.error "HubSpot Integration: Failed to create inbox. Status: #{create_inbox_response.code}, Response: #{create_inbox_response.parsed_response.inspect}"
        # Try to find any existing inbox we can use
        inbox = response.parsed_response['results'].first
        if inbox
          Rails.logger.info "HubSpot Integration: Using existing inbox: #{inbox.inspect}"
          return inbox['id']
        end
      end
    else
      Rails.logger.error "HubSpot Integration: Failed to fetch inboxes. Status: #{response.code}, Response: #{response.parsed_response.inspect}"
      # Try to find any existing inbox we can use
      inbox = response.parsed_response['results']&.first
      if inbox
        Rails.logger.info "HubSpot Integration: Using existing inbox: #{inbox.inspect}"
        return inbox['id']
      end
    end
    
    Rails.logger.error "HubSpot Integration: No inboxes available"
    nil
  end

  def create_or_update_conversation(conversation, contact)
    Rails.logger.info "HubSpot Integration: Creating/updating conversation for conversation #{conversation.id}"
    
    # If contact is nil, try to find it by email
    if contact.nil? && conversation.contact.email.present?
      Rails.logger.info "HubSpot Integration: Contact not found, searching by email: #{conversation.contact.email}"
      response = self.class.get(
        "/crm/v3/objects/contacts",
        headers: @headers,
        query: { filterGroups: [{ filters: [{ propertyName: "email", operator: "EQ", value: conversation.contact.email }] }] }
      )
      
      if response.success? && response.parsed_response['results'].any?
        contact = response.parsed_response['results'].first
        Rails.logger.info "HubSpot Integration: Found existing contact: #{contact.inspect}"
      else
        Rails.logger.error "HubSpot Integration: Could not find contact by email"
        return nil
      end
    end

    # Get or create DashAssist inbox
    inbox_id = get_or_create_dash_assist_inbox
    unless inbox_id
      Rails.logger.error "HubSpot Integration: Failed to get/create DashAssist inbox"
      return nil
    end

    # Create conversation thread
    properties = {
      hsconversation: conversation.id,
      hsconversationstatus: "OPEN",
      hsconversationchannel: "CHAT",
      hsconversationcontact: contact['id'],
      hsconversationinbox: inbox_id
    }
    Rails.logger.info "HubSpot Integration: Conversation properties: #{properties.inspect}"

    response = self.class.post(
      "/conversations/v3/conversations/threads",
      headers: @headers,
      body: { properties: properties }.to_json
    )

    if response.success?
      Rails.logger.info "HubSpot Integration: Conversation API response: #{response.parsed_response.inspect}"
      return response.parsed_response
    else
      Rails.logger.error "HubSpot Integration: Conversation API error: #{response.code} - #{response.parsed_response.inspect}"
      return nil
    end
  end

  def create_message(message, conversation)
    Rails.logger.info "HubSpot Integration: Creating message in conversation: #{conversation['id']}"
    endpoint = "/conversations/v3/conversations/threads/#{conversation['id']}/messages"
    
    properties = {
      text: message.content,
      type: message.incoming? ? "INCOMING" : "OUTGOING",
      senderType: message.incoming? ? "CONTACT" : "USER",
      timestamp: message.created_at.to_i * 1000,
      channelId: conversation['channelId']
    }
    Rails.logger.info "HubSpot Integration: Message properties: #{properties.inspect}"

    response = self.class.post(
      endpoint,
      headers: @headers,
      body: properties.to_json
    )

    if response.success?
      Rails.logger.info "HubSpot Integration: Message API response: #{response.parsed_response.inspect}"
      return response.parsed_response
    else
      Rails.logger.error "HubSpot Integration: Message API error: #{response.code} - #{response.parsed_response.inspect}"
      return nil
    end
  end
end 