class Crm::Leadsquared::ProcessorService < Crm::BaseProcessorService
  def self.crm_name
    'leadsquared'
  end

  def initialize(hook)
    super(hook)
    @access_key = hook.settings['access_key']
    @secret_key = hook.settings['secret_key']
    @endpoint_url = hook.settings['endpoint_url']

    @allow_transcript = hook.settings['enable_transcript_activity']
    @allow_conversation = hook.settings['enable_conversation_activity']

    # Initialize API clients
    @lead_client = Crm::Leadsquared::Api::LeadClient.new(@access_key, @secret_key, @endpoint_url)
    @activity_client = Crm::Leadsquared::Api::ActivityClient.new(@access_key, @secret_key, @endpoint_url)
    @lead_finder = Crm::Leadsquared::LeadFinderService.new(@lead_client)
  end

  def handle_contact(contact)
    contact.reload
    unless identifiable_contact?(contact)
      Rails.logger.info("Contact not identifiable. Skipping handle_contact for ##{contact.id}")
      return
    end

    stored_lead_id = get_external_id(contact)
    create_or_update_lead(contact, stored_lead_id)
  end

  def handle_conversation_created(conversation)
    return unless @allow_conversation

    create_conversation_activity(
      conversation: conversation,
      activity_type: 'conversation',
      activity_code_key: 'conversation_activity_code',
      metadata_key: 'created_activity_id',
      activity_note: Crm::Leadsquared::Mappers::ConversationMapper.map_conversation_activity(@hook, conversation)
    )
  end

  def handle_conversation_resolved(conversation)
    return unless @allow_transcript
    return unless conversation.status == 'resolved'

    create_conversation_activity(
      conversation: conversation,
      activity_type: 'transcript',
      activity_code_key: 'transcript_activity_code',
      metadata_key: 'transcript_activity_id',
      activity_note: Crm::Leadsquared::Mappers::ConversationMapper.map_transcript_activity(@hook, conversation)
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
    ChatwootExceptionTracker.new(e, account: @account).capture_exception
    Rails.logger.error "LeadSquared API error processing contact: #{e.message}"
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: @account).capture_exception
    Rails.logger.error "Error processing contact in LeadSquared: #{e.message}"
  end

  def create_conversation_activity(conversation:, activity_type:, activity_code_key:, metadata_key:, activity_note:)
    lead_id = get_lead_id(conversation.contact)
    return if lead_id.blank?

    activity_code = get_activity_code(activity_code_key)
    activity_id = @activity_client.post_activity(lead_id, activity_code, activity_note)
    return if activity_id.blank?

    metadata = {}
    metadata[metadata_key] = activity_id
    store_conversation_metadata(conversation, metadata)
  rescue Crm::Leadsquared::Api::BaseClient::ApiError => e
    ChatwootExceptionTracker.new(e, account: @account).capture_exception
    Rails.logger.error "LeadSquared API error in #{activity_type} activity: #{e.message}"
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: @account).capture_exception
    Rails.logger.error "Error creating #{activity_type} activity in LeadSquared: #{e.message}"
  end

  def get_activity_code(key)
    activity_code = @hook.settings[key]
    raise StandardError, "LeadSquared #{key} activity code not found for hook ##{@hook.id}." if activity_code.blank?

    activity_code
  end

  def get_lead_id(contact)
    contact.reload # reload to ensure all the attributes are up-to-date

    unless identifiable_contact?(contact)
      Rails.logger.info("Contact not identifiable. Skipping activity for ##{contact.id}")
      nil
    end

    lead_id = @lead_finder.find_or_create(contact)
    return nil if lead_id.blank?

    store_external_id(contact, lead_id) unless get_external_id(contact)

    lead_id
  end
end
