class AppleMessagesForBusiness::ConversationReopenService
  def initialize(inbox:, source_id:)
    @inbox = inbox
    @source_id = source_id
  end

  def perform
    Rails.logger.info "[AMB ConversationReopen] Re-enabling messages for source_id: #{@source_id}"

    # Find the contact and contact_inbox using proper JSONB syntax
    contact_inbox = ContactInbox.joins(:contact)
                                .where(inbox: @inbox)
                                .where("contacts.additional_attributes->>'apple_messages_source_id' = ?", @source_id)
                                .first

    return unless contact_inbox

    contact = contact_inbox.contact

    # Remove blocking flags from contact
    if contact.additional_attributes&.dig('apple_messages_blocked')
      contact_attrs = contact.additional_attributes.dup
      contact_attrs.delete('apple_messages_blocked')
      contact_attrs.delete('apple_messages_blocked_at')
      contact_attrs.delete('apple_messages_block_reason')
      contact_attrs.delete('apple_close_event_id')  # Remove the close event reference
      contact_attrs['apple_messages_reopened_at'] = Time.current.iso8601
      contact_attrs['apple_messages_reopen_reason'] = 'customer_message_received'
      contact.additional_attributes = contact_attrs
      contact.save!
      Rails.logger.info "[AMB ConversationReopen] Unblocked contact #{contact.id}"

      # Broadcast contact update to refresh UI
      contact.dispatch_contact_updated_event
    end

    Rails.logger.info "[AMB ConversationReopen] Successfully re-enabled messages for source_id: #{@source_id}"
  end
end
