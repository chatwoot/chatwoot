class Messages::InReplyToMessageBuilder
  pattr_initialize [:message!, :in_reply_to!, :in_reply_to_external_id!]

  delegate :conversation, to: :message

  def perform
    set_in_reply_to_attribute if @in_reply_to.present? || @in_reply_to_external_id.present?
  end

  private

  def set_in_reply_to_attribute
    @message.content_attributes[:in_reply_to_external_id] = in_reply_to_message.try(:source_id)
    @message.content_attributes[:in_reply_to] = in_reply_to_message.try(:id)
  end

  def in_reply_to_message
    return conversation.messages.find_by(id: @in_reply_to) if @in_reply_to.present?

    if @in_reply_to_external_id.present?
      # First try to find by primary source_id
      msg = conversation.messages.find_by(source_id: @in_reply_to_external_id)
      return msg if msg.present?

      # For Instagram messages with multiple parts (text + attachments),
      # search in external_source_ids where all Instagram message IDs are stored
      msg = find_by_instagram_external_id(@in_reply_to_external_id)
      return msg if msg.present?
    end

    nil
  end

  # Find message by searching through external_source_ids['instagram'] array
  # This handles cases where Instagram sends multiple message IDs for a single Chatwoot message
  # (e.g., text + 2 images = 3 separate Instagram message IDs)
  def find_by_instagram_external_id(external_id)
    return nil if conversation.inbox.channel_type != 'Channel::FacebookPage'

    conversation.messages.find do |message|
      next unless message.external_source_ids.present? && message.external_source_ids['instagram'].is_a?(Array)

      message.external_source_ids['instagram'].include?(external_id)
    end
  end
end
