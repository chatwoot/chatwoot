class Crm::Leadsquared::ProcessorService < Crm::BaseProcessorService
  # Activity codes should be set via the setup service
  # We don't want to use defaults as they might be invalid for the specific LeadSquared account

  def self.crm_name
    'leadsquared'
  end

  def initialize(hook)
    super(hook)
    @access_key = @hook.settings['access_key']
    @secret_key = @hook.settings['secret_key']
    @endpoint_url = @hook.settings['endpoint_url']

    @allow_transcript = @hook.settings['enable_transcript_activity']
    @allow_conversation = @hook.settings['enable_conversation_activity']

    # Initialize API clients
    @lead_client = Crm::Leadsquared::Api::LeadClient.new(@access_key, @secret_key, @endpoint_url)
    @activity_client = Crm::Leadsquared::Api::ActivityClient.new(@access_key, @secret_key, @endpoint_url)
    @lead_finder = Crm::Leadsquared::LeadFinderService.new(@lead_client)
  end

  def handle_contact(contact)
    return unless contact_valid?(contact)

    stored_lead_id = get_external_id(contact)
    create_or_update_lead(contact, stored_lead_id)
  end

  def handle_conversation_created(conversation)
    return unless @allow_conversation

    # Create activity for a new conversation
    create_conversation_activity(
      conversation: conversation,
      activity_type: 'conversation',
      activity_code_key: 'conversation_activity_code',
      metadata_key: 'created_activity_id',
      mapper_method: :map_conversation_activity
    )
  end

  def handle_conversation_resolved(conversation)
    # if transcript is not allowed return
    return unless @allow_transcript

    # We'll only sync transcripts for closed conversations
    return unless conversation.status == 'resolved'

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

    # Why can't we use create_or_update_lead here?
    # In LeadSquared, it's possible that the email field
    # may not be marked as unique, same with the phone number field
    # So we just use the update API if we already have a lead ID
    if lead_id.present?
      @lead_client.update_lead(lead_data, lead_id)
    else
      new_lead_id = @lead_client.create_or_update_lead(lead_data)
      store_external_id(contact, new_lead_id)
    end
  rescue Crm::Leadsquared::Api::BaseClient::ApiError => e
    Rails.logger.error "LeadSquared API error processing contact: #{e.message}"
  rescue StandardError => e
    Rails.logger.error "Error processing contact in LeadSquared: #{e.message}"
  end

  def create_conversation_activity(conversation:, activity_type:, activity_code_key:, metadata_key:, mapper_method:)
    contact = conversation.contact
    lead_id = @lead_finder.find_or_create(contact)
    return if lead_id.blank?

    store_external_id(contact, lead_id)

    activity_note = Crm::Leadsquared::Mappers::ConversationMapper.send(mapper_method, conversation)
    activity_code = @hook.settings[activity_code_key]

    if activity_code.blank?
      Rails.logger.warn "LeadSquared #{activity_type} activity code not found for hook ##{@hook.id}. Setup may not have completed."
      return
    end

    # Post the activity to LeadSquared
    activity_id = @activity_client.post_activity(lead_id, activity_code, activity_note)
    return if activity_id.blank?

    # Store activity reference in conversation metadata
    metadata = {}
    metadata[metadata_key] = activity_id
    store_conversation_metadata(conversation, metadata)
  rescue Crm::Leadsquared::Api::BaseClient::ApiError => e
    Rails.logger.error "LeadSquared API error in #{activity_type} activity: #{e.message}"
  rescue StandardError => e
    Rails.logger.error "Error creating #{activity_type} activity in LeadSquared: #{e.message}"
  end
end
