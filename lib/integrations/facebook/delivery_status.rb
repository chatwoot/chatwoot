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

  def conversation
    @conversation ||= Conversation.find_by(sender_id: sender_id)
  end

  def update_message_status
    conversation.user_last_seen_at = @params.at
    conversation.save!
  end
end
