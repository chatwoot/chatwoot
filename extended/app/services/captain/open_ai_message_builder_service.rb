module Captain
  class OpenAiMessageBuilderService
    def initialize(message:)
      @message = message
    end

    def generate_content
      components = []

      # Add text content if present
      components << build_text_block(@message.content) if @message.content.present?

      # Process attachments if any
      components.concat(process_attachments(@message.attachments)) if @message.attachments.any?

      return fallback_message if components.empty?

      # Return simple string if only one text component
      return components.first[:text] if components.one? && components.first[:type] == 'text'

      components
    end

    private

    def build_text_block(content)
      { type: 'text', text: content }
    end

    def build_image_block(url)
      { type: 'image_url', image_url: { url: url } }
    end

    def process_attachments(attachments)
      parts = []

      # Handle images
      images = attachments.where(file_type: :image)
      parts.concat(extract_image_parts(images))

      # Handle audio transcriptions
      transcription = transcribe_audio(attachments)
      parts << build_text_block(transcription) if transcription.present?

      # Handle other file types
      parts << build_text_block('User has shared an attachment') if attachments.where.not(file_type: %i[image audio]).exists?

      parts
    end

    def extract_image_parts(images)
      images.map do |img|
        url = resolve_url(img)
        url.present? ? build_image_block(url) : nil
      end.compact
    end

    def resolve_url(attachment)
      return attachment.download_url if attachment.download_url.present?
      return attachment.external_url if attachment.external_url.present?

      attachment.file.attached? ? attachment.file_url : nil
    end

    def transcribe_audio(attachments)
      audio_attachments = attachments.select(&:audio?)
      return nil if audio_attachments.empty?

      results = audio_attachments.filter_map do |attachment|
        result = Messages::AudioTranscriptionService.new(attachment).perform
        next nil if result.is_a?(Hash) && result[:error].present?
        next nil if result.is_a?(Hash) && result[:transcriptions].blank?

        text = result.is_a?(Hash) ? result[:transcriptions] : result
        text.to_s.strip
      end

      results.join(' ').presence
    end

    def fallback_message
      'Message without content'
    end
  end
end
