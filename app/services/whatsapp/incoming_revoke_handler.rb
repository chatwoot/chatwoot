# WhatsApp sends type: revoke when a message is deleted for everyone, by the contact (messages) or from the
# WhatsApp Business app (message_echoes). The event has no content of its own and only names the deleted
# message, so we tombstone that message instead of storing a new, empty one.
module Whatsapp::IncomingRevokeHandler
  # Meta retries a failed webhook for up to 7 days, so an original can land that long after its revoke
  REVOKE_TOMBSTONE_TTL = 7.days.to_i

  def revoke_event?
    message_type == 'revoke'
  end

  def process_revoke
    original_message_id = messages_data.first.dig(:revoke, :original_message_id)
    return if original_message_id.blank?

    stored_messages = @inbox.messages.where(source_id: original_message_id).to_a
    # The revoke can overtake its original: the sender lock is not FIFO, a slow media download can outlast it,
    # and Meta redelivers failed webhooks. Remember it so the original is tombstoned once it is stored.
    return record_revoke_tombstone(original_message_id) if stored_messages.empty?

    # A contact can only revoke what they sent, the business app only what the business sent.
    # A shared contacts message is stored as one row per contact, all with the same source id.
    stored_messages.select { |message| message.outgoing? == outgoing_echo.present? }
                   .reject(&:deleted)
                   .each { |message| tombstone_message(message) }
  end

  def apply_pending_revoke
    source_id = messages_data.first[:id]
    return unless ::Redis::Alfred.exists?(revoke_tombstone_key(source_id))

    @inbox.messages.where(source_id: source_id).reject(&:deleted).each { |message| tombstone_message(message) }
  end

  private

  # Same tombstone as an agent delete, so structured attributes such as a Flow response are dropped too.
  # Saved without validations: the flood guard counts recent messages and would reject it in a busy conversation.
  def tombstone_message(message)
    Message.transaction do
      message.attachments.destroy_all
      message.assign_attributes(content: I18n.t('conversations.messages.deleted'), content_type: :text,
                                content_attributes: message.content_attributes.slice('forwarded_message_id').merge(deleted: true))
      message.save!(validate: false)
    end
  end

  def record_revoke_tombstone(original_message_id)
    ::Redis::Alfred.setex(revoke_tombstone_key(original_message_id), true, REVOKE_TOMBSTONE_TTL)
  end

  def revoke_tombstone_key(source_id)
    format(::Redis::Alfred::WHATSAPP_REVOKE_TOMBSTONE, inbox_id: @inbox.id, source_id: source_id)
  end
end
