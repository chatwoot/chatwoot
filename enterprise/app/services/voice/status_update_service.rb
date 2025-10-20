class Voice::StatusUpdateService
  pattr_initialize [:account!, :call_sid!, :call_status]

  def perform
    conversation = account.conversations.find_by(identifier: call_sid)
    return unless conversation
    return if call_status.to_s.strip.empty?

    update_conversation!(conversation)
    update_last_call_message!(conversation)
  end

  private

  def update_conversation!(conversation)
    attrs = (conversation.additional_attributes || {}).merge('call_status' => call_status)
    conversation.update!(additional_attributes: attrs)
  end

  def update_last_call_message!(conversation)
    msg = conversation.messages.voice_calls.order(created_at: :desc).first
    return unless msg

    data = msg.content_attributes.is_a?(Hash) ? msg.content_attributes : {}
    data['data'] ||= {}
    data['data']['status'] = call_status
    msg.update!(content_attributes: data)
  end
end
