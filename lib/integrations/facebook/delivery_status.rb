# frozen_string_literal: true

class Integrations::Facebook::DeliveryStatus
  def initialize(params)
    @params = params
  end

  def perform
    update_message_status
  end

  private

  def sender_id
    @params.sender['id']
  end

  def contact
    ::ContactInbox.find_by(source_id: sender_id).contact
  end

  def conversation
    @conversation ||= ::Conversation.find_by(contact_id: contact.id)
  end

  def update_message_status
    conversation.user_last_seen_at = @params.at
    conversation.save!
  end
end
