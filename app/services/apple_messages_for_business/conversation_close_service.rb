class AppleMessagesForBusiness::ConversationCloseService
  def initialize(inbox:, params:, headers:)
    @inbox = inbox
    @params = params
    @headers = headers
  end

  def perform
    Rails.logger.info '[AMB ConversationClose] Starting conversation close processing'
    Rails.logger.info "[AMB ConversationClose] Params: #{@params.inspect}"
    Rails.logger.info "[AMB ConversationClose] Headers: #{@headers.inspect}"

    return unless valid_close_event?

    find_conversation
    return unless @conversation

    close_conversation
    block_future_messages
    create_activity_message

    Rails.logger.info '[AMB ConversationClose] Conversation close processing completed successfully'
  end

  private

  def valid_close_event?
    has_id = @params['id'].present?
    has_source_id = source_id.present?

    Rails.logger.info "[AMB ConversationClose] Validation - ID: #{has_id}, Source ID: #{has_source_id}"

    valid = has_id && has_source_id
    Rails.logger.info "[AMB ConversationClose] Close event validation result: #{valid}"

    valid
  end

  def find_conversation
    Rails.logger.info "[AMB ConversationClose] Looking for conversation with source_id: #{source_id}"

    # Find the contact first
    contact_inbox = ContactInbox.joins(:contact)
                                .where(inbox: @inbox)
                                .where(contacts: { additional_attributes: { apple_messages_source_id: source_id } })
                                .first

    unless contact_inbox
      Rails.logger.warn "[AMB ConversationClose] No contact found for source_id: #{source_id}"
      return
    end

    # Find the most recent conversation for this contact (include resolved to handle repeated close events)
    @conversation = contact_inbox.conversations
                                 .where(status: [:open, :pending, :resolved])
                                 .order(updated_at: :desc)
                                 .first

    if @conversation
      Rails.logger.info "[AMB ConversationClose] Found conversation to close - ID: #{@conversation.id}, Status: #{@conversation.status}"
      @contact_inbox = contact_inbox
      @contact = contact_inbox.contact
    else
      Rails.logger.warn "[AMB ConversationClose] No active conversation found for source_id: #{source_id}"
    end
  end

  def close_conversation
    Rails.logger.info "[AMB ConversationClose] Closing conversation ID: #{@conversation.id}"

    # Skip if conversation is already closed by AMB (avoid duplicate processing)
    if @conversation.status == 'resolved' &&
       @conversation.additional_attributes&.dig('closed_by') == 'apple_messages_for_business'
      Rails.logger.info "[AMB ConversationClose] Conversation #{@conversation.id} already closed by AMB, skipping"
      return
    end

    # Mark conversation as resolved
    @conversation.status = :resolved
    @conversation.resolved_at = Time.current

    # Add close reason to additional attributes
    additional_attrs = @conversation.additional_attributes || {}
    additional_attrs['closed_by'] = 'apple_messages_for_business'
    additional_attrs['close_reason'] = 'customer_opted_out'
    additional_attrs['closed_at'] = Time.current.iso8601
    additional_attrs['apple_close_event_id'] = @params['id']
    @conversation.additional_attributes = additional_attrs

    @conversation.save!

    Rails.logger.info "[AMB ConversationClose] Conversation #{@conversation.id} closed successfully"
  end

  def block_future_messages
    Rails.logger.info "[AMB ConversationClose] Blocking future messages for source_id: #{source_id}"

    # CRITICAL REQUIREMENT: Block this user from receiving further messages
    # as per Apple MSP specification

    # Mark contact as blocked for Apple Messages
    contact_attrs = @contact.additional_attributes || {}
    contact_attrs['apple_messages_blocked'] = true
    contact_attrs['apple_messages_blocked_at'] = Time.current.iso8601
    contact_attrs['apple_messages_block_reason'] = 'customer_opted_out'
    contact_attrs['apple_close_event_id'] = @params['id']
    @contact.additional_attributes = contact_attrs
    @contact.save!

    Rails.logger.info "[AMB ConversationClose] Contact #{@contact.id} marked as blocked"
  end

  def create_activity_message
    Rails.logger.info '[AMB ConversationClose] Creating activity message for conversation close'

    @conversation.messages.create!(
      content: 'Customer opted out of receiving messages via Apple Messages. No further messages can be sent to this user.',
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      message_type: :activity,
      sender: nil,
      content_type: 'text',
      content_attributes: {
        automation_rule_id: nil,
        system_generated: true,
        close_event_id: @params['id'],
        closed_by: 'apple_messages_for_business',
        blocked_user: true
      },
      source_id: @params['id']
    )

    Rails.logger.info '[AMB ConversationClose] Activity message created successfully'

    # Force UI refresh by broadcasting conversation update
    @conversation.dispatch_conversation_updated_event
  end

  def source_id
    @headers[:source_id] || @params['sourceId']
  end
end
