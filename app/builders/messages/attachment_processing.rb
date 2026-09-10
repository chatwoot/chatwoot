module Messages::AttachmentProcessing
  private

  def process_attachments
    return if @attachments.blank?

    @attachments.each do |uploaded_attachment|
      attachment = @message.attachments.build(
        account_id: @message.account_id,
        file: uploaded_attachment
      )

      attachment.file_type = attachment_file_type(uploaded_attachment)
      tag_voice_message(attachment)
    end
  end

  def process_reusable_attachments
    return if @attachment_ids.blank?

    resolved = @account.reusable_attachments.where(id: @attachment_ids).in_order_of(:id, @attachment_ids)
    raise ActiveRecord::RecordNotFound, 'No reusable attachments found for provided ids' if resolved.empty?

    resolved.each do |reusable|
      next unless reusable.file.attached?

      attachment = @message.attachments.build(account_id: @message.account_id, file: reusable.file.blob)
      attachment.file_type = reusable.file_type
      attachment.extension = reusable.extension
      tag_voice_message(attachment)
    end
  end

  def attachment_file_type(uploaded_attachment)
    if uploaded_attachment.is_a?(String)
      file_type_by_signed_id(uploaded_attachment)
    else
      file_type(uploaded_attachment&.content_type)
    end
  end

  def tag_voice_message(attachment)
    return unless @is_voice_message && attachment.file_type == 'audio'

    attachment.meta = (attachment.meta || {}).merge('is_voice_message' => true)
  end
end
