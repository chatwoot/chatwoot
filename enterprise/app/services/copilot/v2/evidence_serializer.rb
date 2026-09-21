class Copilot::V2::EvidenceSerializer
  def self.message(message)
    parts, limitations = text_parts(message)
    attachment_parts(message, parts, limitations)
    if message.call&.transcript.present?
      parts << { 'id' => "call:#{message.call.id}:transcript", 'call_id' => message.call.id,
                 'provenance' => 'call_transcript', 'text' => message.call.transcript }
    end
    { 'id' => message.id, 'conversation_id' => message.conversation_id, 'display_id' => message.conversation.display_id,
      'speaker' => { 'type' => message.sender_type, 'id' => message.sender_id }, 'message_type' => message.message_type,
      'private' => message.private?, 'created_at' => message.created_at.iso8601(6), 'parts' => parts, 'limitations' => limitations }
  end

  def self.text_parts(message)
    parts = []
    parts << { 'id' => "message:#{message.id}:body", 'provenance' => 'body', 'text' => message.content } if message.content.present?
    limitations = []
    if message.content_attributes['email'].present? && message.processed_message_content.present?
      parts << { 'id' => "message:#{message.id}:email", 'provenance' => 'processed_email', 'text' => message.processed_message_content }
      limitations << 'processed_email_may_be_truncated'
    end
    [parts, limitations]
  end

  def self.attachment_parts(message, parts, limitations)
    message.attachments.each do |attachment|
      transcript = attachment.meta&.dig('transcribed_text')
      if transcript.present?
        parts << { 'id' => "attachment:#{attachment.id}:transcript", 'attachment_id' => attachment.id,
                   'provenance' => 'attachment_transcript', 'text' => transcript }
      else
        limitations << { 'reason' => 'unexamined_attachment', 'attachment_id' => attachment.id, 'file_type' => attachment.file_type }
      end
    end
  end
  private_class_method :text_parts, :attachment_parts
end
