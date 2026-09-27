# Builds a message's attachments: uploaded files, and GIFs picked from Giphy.
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

  # A Giphy GIF is kept as a link to Giphy rather than a stored copy of the file.
  def process_giphy
    giphy = ensure_indifferent_access(convert_to_hash(@params)[:giphy])
    return if giphy.blank?

    @message.attachments.build(
      account_id: @message.account_id,
      file_type: :image,
      external_url: giphy[:url],
      meta: { 'giphy' => giphy.slice(*Attachment::GIPHY_ATTRIBUTES).to_h }
    )
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
