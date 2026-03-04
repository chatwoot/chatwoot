# frozen_string_literal: true

# Marks unread incoming WhatsApp messages as read via the Cloud API
# when an agent opens the conversation. Sends blue double-check marks
# to the contact's WhatsApp client.
#
# Enqueued from ConversationsController#update_last_seen for WhatsApp inboxes.
class Whatsapp::MarkReadJob < ApplicationJob
  queue_as :low

  def perform(conversation)
    channel = conversation.inbox&.channel
    return unless channel.is_a?(Channel::Whatsapp)
    return unless channel.provider == 'whatsapp_cloud'

    unread = conversation.unread_incoming_messages.select { |m| m.source_id.present? }
    return if unread.empty?

    # Mark only the most recent message — WhatsApp treats this as marking
    # all earlier messages as read (same behavior as the mobile app).
    last_message = unread.last
    channel.mark_as_read(last_message.source_id)
  end
end
