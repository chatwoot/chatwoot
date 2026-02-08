# frozen_string_literal: true

class Integrations::Facebook::DeliveryStatus
  pattr_initialize [:params!]

  def perform
    return if facebook_channel.blank?
    return unless conversation

    process_delivery_status if params.delivery_watermark
    process_read_status if params.read_watermark
  end

  private

  def process_delivery_status
    timestamp = Time.zone.at(params.delivery_watermark.to_i).to_datetime.utc
    ::Conversations::UpdateMessageStatusJob.perform_later(conversation.id, timestamp, :delivered)
  end

  def process_read_status
    timestamp = Time.zone.at(params.read_watermark.to_i).to_datetime.utc
    ::Conversations::UpdateMessageStatusJob.perform_later(conversation.id, timestamp, :read)
  end

  def contact
    ::ContactInbox.find_by(source_id: params.sender_id)&.contact
  end

  def conversation
    return @conversation if defined?(@conversation)
    return nil unless contact.present?

    scope = ::Conversation.where(contact_id: contact.id)
    inbox = facebook_channel&.inbox
    scope = scope.where(inbox_id: inbox.id) if inbox

    # pick the most recent conversation for this contact + inbox
    @conversation = scope.order(id: :desc).first
  end

  def facebook_channel
    @facebook_channel ||= Channel::FacebookPage.find_by(page_id: params.recipient_id)
  end
end
