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

  def contact_id
    @contact ||= ::Contact.find_by(source_id: sender_id)
  end

  def conversation
    @conversation ||= ::Conversation.find_by(sender_id: contact_id)
  end

  def update_message_status
    conversation.user_last_seen_at = @params.at
    conversation.save!
  end
end
