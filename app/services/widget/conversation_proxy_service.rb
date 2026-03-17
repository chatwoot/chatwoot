class Widget::ConversationProxyService
  def initialize(widget_conversation, message_params)
    @widget_conversation = widget_conversation
    @message_params = message_params || {}
  end

  def mirror_incoming_from_widget
    return if Thread.current[:mirroring_widget_message]

    target_conversation = linked_conversation
    return if target_conversation.blank?

    has_content = @message_params[:content].present?
    has_attachments = @message_params[:attachment_ids].present?
    return unless has_content || has_attachments

    Thread.current[:mirroring_widget_message] = true

    mirrored = target_conversation.messages.create!(
      account_id: target_conversation.account_id,
      inbox_id: target_conversation.inbox_id,
      message_type: :incoming,
      content: @message_params[:content].presence,
      sender: @widget_conversation.contact,
      source_id: @message_params[:echo_id]
    )

    mirror_attachments(mirrored)

    Rails.logger.info('[ProxyService] CREATED mirrored incoming message')
  rescue StandardError => e
    Rails.logger.error("[ProxyService] failed: #{e.class} - #{e.message}")
  ensure
    Thread.current[:mirroring_widget_message] = nil
  end

  private

  def mirror_attachments(mirrored_message)
    return if @message_params[:attachment_ids].blank?

    @message_params[:attachment_ids].each do |attachment_id|
      original = Attachment.find_by(id: attachment_id)
      next if original.blank? || !original.file.attached?

      new_attachment = mirrored_message.attachments.create!(
        account_id: mirrored_message.account_id,
        file_type: original.file_type
      )

      new_attachment.file.attach(original.file.blob)
      new_attachment.save!
    rescue StandardError => e
      Rails.logger.error("[ProxyService] failed to mirror attachment #{attachment_id}: #{e.message}")
    end
  end

  def linked_conversation
    linked_id = @widget_conversation.additional_attributes&.dig('linked_conversation_id')
    return if linked_id.blank?

    Conversation.find_by(id: linked_id)
  end
end
