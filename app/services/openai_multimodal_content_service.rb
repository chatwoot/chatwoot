class OpenaiMultimodalContentService
  def initialize(message)
    @message = message
  end

  def generate_content
    parts = []

    parts << text_part(@message.content) if @message.content.present?
    parts.concat(attachment_parts(@message.attachments)) if @message.attachments.any?

    finalize_content_parts(parts)
  end

  private

  def text_part(text)
    { type: 'text', text: text }
  end

  def attachment_parts(attachments)
    [].tap do |parts|
      parts.concat(image_parts(attachments.where(file_type: :image)))

      transcription = extract_audio_transcriptions(attachments)
      parts << text_part(transcription) if transcription.present?

      parts << text_part('User has shared an attachment') if attachments.where.not(file_type: %i[image audio]).exists?
    end
  end

  def image_parts(image_attachments)
    image_attachments.each_with_object([]) do |attachment, parts|
      url = get_attachment_url(attachment)
      next if url.blank?

      parts << {
        type: 'image_url',
        image_url: { url: url }
      }
    end
  end

  def finalize_content_parts(parts)
    return 'Message without content' if parts.blank?
    return parts.first[:text] if single_text_part?(parts)

    parts
  end

  def single_text_part?(parts)
    parts.one? && parts.first[:type] == 'text'
  end

  def get_attachment_url(attachment)
    return attachment.external_url if attachment.external_url.present?

    return unless attachment.file.attached?

    attachment.file_url
  end

  def extract_audio_transcriptions(attachments)
    audio_attachments = attachments.where(file_type: :audio)
    return '' if audio_attachments.blank?

    transcriptions = ''
    audio_attachments.each do |attachment|
      result = Messages::AudioTranscriptionService.new(attachment).perform
      transcriptions += result[:transcriptions] if result[:success]
    end
    transcriptions
  end
end