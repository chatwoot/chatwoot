class Zalo::Messages::BaseService
  delegate :inbox, :account, :contact, to: :conversation
  delegate :channel, to: :inbox

  pattr_initialize :conversation, :params

  def process
    return if skip_processing?

    conversation.with_lock do
      build_message
      process_attachments
      @message.save!
    end
  rescue StandardError => e
    Rails.logger.error("Failed to process message: #{e.message}")
    raise e
  end

  private

  def skip_processing?
    conversation.messages.exists?(source_id: message_id) ||
      Attachment.exists?(external_code: message_id, account_id: account.id)
  end

  def message_id
    @message_id ||= params.dig(:message, :msg_id)
  end

  def message_content
    @message_content ||= params.dig(:message, :text).presence
  end

  def message_attachments
    @message_attachments ||= params.dig(:message, :attachments) || []
  end

  def message_type
    @message_type ||= params[:event_name].start_with?('oa_') ? :outgoing : :incoming
  end

  def sender
    @sender ||= message_type == :incoming ? contact : nil
  end

  def message_attributes
    {
      status: :delivered,
      sender: sender,
      inbox_id: inbox.id,
      account_id: account.id,
      content: message_content,
      message_type: message_type,
      content_type: content_type,
      content_attributes: content_attributes
    }
  end

  def content_attributes
    {
      in_reply_to_external_id: params.dig(:message, :quote_msg_id),
      app_id: params[:app_id],
      timestamp: params[:timestamp],
      event_name: params[:event_name],
      admin_id: params.dig(:sender, :admin_id)
    }
  end

  def build_message
    @message = conversation.messages.find_or_initialize_by(source_id: message_id)
    @message.assign_attributes(message_attributes)
  end

  def process_attachments; end
end
