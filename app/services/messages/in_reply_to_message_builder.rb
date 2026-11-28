class Messages::InReplyToMessageBuilder
  pattr_initialize [:message!, :in_reply_to!, :in_reply_to_external_id!]

  delegate :conversation, to: :message

  def perform
    set_in_reply_to_attribute if @in_reply_to.present? || @in_reply_to_external_id.present?
  end

  private

  def set_in_reply_to_attribute
    @message.content_attributes[:in_reply_to_external_id] = in_reply_to_external_id
    @message.content_attributes[:in_reply_to] = in_reply_to_message.try(:id)
  end

  # Incoming messages keep the provider's id when the quoted message lives in another conversation.
  # Outgoing messages drop it, because senders forward it to the provider as reply context.
  def in_reply_to_external_id
    return in_reply_to_message&.source_id || @in_reply_to_external_id if @message.incoming?

    in_reply_to_message.try(:source_id)
  end

  def in_reply_to_message
    return conversation.messages.find_by(id: @in_reply_to) if @in_reply_to.present?

    return conversation.messages.find_by(source_id: @in_reply_to_external_id) if @in_reply_to_external_id

    nil
  end
end
