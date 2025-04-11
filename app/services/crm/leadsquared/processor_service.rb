class Crm::Leadsquared::ProcessorService < Crm::BaseProcessorService
  # Activity codes should be set via the setup service
  # We don't want to use defaults as they might be invalid for the specific LeadSquared account

  def self.crm_name
    'leadsquared'
  end

  def initialize(hook)
    super(hook)
    credentials = @hook.settings

    @access_key = credentials['access_key']
    @secret_key = credentials['secret_key']
    @endpoint_url = credentials['endpoint_url']

    # Initialize API clients
    @lead_client = Crm::Leadsquared::Api::LeadClient.new(@access_key, @secret_key, @endpoint_url)
    @activity_client = Crm::Leadsquared::Api::ActivityClient.new(@access_key, @secret_key, @endpoint_url)
  end

  def handle_contact_created(contact)
    create_or_update_lead(contact, nil)
  end

  def handle_contact_updated(contact)
    lead_id = get_external_id(contact)
    create_or_update_lead(contact, lead_id)
  end

  def handle_conversation_created(conversation)
    # Create activity for a new conversation
    create_conversation_activity(
      conversation: conversation,
      activity_type: 'conversation',
      activity_code_key: 'conversation_activity_code',
      metadata_key: 'activity_id',
      mapper_method: :map_conversation_activity
    )
  end

  def handle_conversation_updated(conversation)
    # We'll only sync transcripts for closed conversations
    return { success: true } unless conversation.status == 'resolved'

    # Create activity for a conversation transcript
    create_conversation_activity(
      conversation: conversation,
      activity_type: 'transcript',
      activity_code_key: 'transcript_activity_code',
      metadata_key: 'transcript_activity_id',
      mapper_method: :map_transcript_activity
    )
  end

  private

  def create_or_update_lead(contact, lead_id)
    lead_data = Crm::Leadsquared::Mappers::ContactMapper.map(contact)

    response = @lead_client.create_or_update_lead(lead_data)

    # If we didn't have a lead ID before but created one, store it
    if response[:success] && lead_id.blank?
      response_lead_id = response[:data].dig('Value', 'ProspectId')
      store_external_id(contact, response_lead_id) if response_lead_id.present?
    end

    response
  end

  def create_conversation_activity(conversation:, activity_type:, activity_code_key:, metadata_key:, mapper_method:)
    # Get the contact associated with the conversation
    contact = conversation.contact
    return { success: false, error: 'Contact not found for conversation' } unless contact

    # Get LeadSquared lead ID for the contact
    lead_id = get_or_find_lead_id(contact)
    return { success: false, error: 'Lead not found in LeadSquared' } unless lead_id

    # Create activity note using the specified mapper method
    activity_note = Crm::Leadsquared::Mappers::ConversationMapper.send(mapper_method, conversation)

    # Get activity code from settings
    activity_code = @hook.settings[activity_code_key]

    if activity_code.blank?
      Rails.logger.warn "LeadSquared #{activity_type} activity code not found for hook ##{@hook.id}. Setup may not have completed."
      return { success: false, error: 'Activity code not found. Please run setup for this integration.' }
    end

    # Post the activity to LeadSquared
    response = @activity_client.post_activity(lead_id, activity_code, activity_note)

    # Store activity reference in conversation metadata if successful
    if response[:success]
      metadata = {}
      metadata[metadata_key] = response[:data].dig('Value', 'Id')
      store_conversation_metadata(conversation, metadata)
    end

    response
  end

  def find_lead_in_leadsquared(contact)
    # Try searching by email
    if contact.email.present?
      response = @lead_client.search_lead(contact.email)

      if response[:success] && response[:data].is_a?(Array) && response[:data].any?
        return { success: true, lead_id: response[:data].first['ProspectID'] }
      end
    end

    # Try searching by phone if email search failed
    if contact.phone_number.present?
      response = @lead_client.search_lead(contact.phone_number)

      if response[:success] && response[:data].is_a?(Array) && response[:data].any?
        return { success: true, lead_id: response[:data].first['ProspectID'] }
      end
    end

    # No lead found
    { success: false }
  end

  def get_or_find_lead_id(contact)
    # First check if we already have a stored ID
    lead_id = get_external_id(contact)
    return lead_id if lead_id.present?

    # If not, search for it in LeadSquared
    found_lead = find_lead_in_leadsquared(contact)

    if found_lead[:success]
      # Store the ID for future use
      store_external_id(contact, found_lead[:lead_id])
      return found_lead[:lead_id]
    end

    # If still not found, create a new lead
    lead_data = Crm::Leadsquared::Mappers::ContactMapper.map(contact)
    response = @lead_client.create_or_update_lead(lead_data)

    if response[:success]
      # Search for the newly created lead to get its ID
      search_key = contact.email || contact.phone_number
      search_response = @lead_client.search_lead(search_key)

      if search_response[:success] && search_response[:data].is_a?(Array) && search_response[:data].any?
        lead_id = search_response[:data].first['ProspectID']
        store_external_id(contact, lead_id)
        return lead_id
      end
    end

    nil
  end
end
