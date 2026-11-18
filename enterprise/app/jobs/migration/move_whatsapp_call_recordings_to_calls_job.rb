# WhatsApp call recordings used to be stored as an audio attachment on the call's message. They now live on the
# call, as Twilio's do. This moves the existing ones without copying the file, and brings the transcript along.
class Migration::MoveWhatsappCallRecordingsToCallsJob < ApplicationJob
  queue_as :async_database_migration

  def perform
    Call.whatsapp.where.not(message_id: nil).includes(message: { attachments: :file_attachment }).find_each do |call|
      attachment = call.message.attachments.find { |message_attachment| message_attachment.audio? && message_attachment.file.attached? }
      move_recording(call, attachment) if attachment.present?
    end
  end

  private

  def move_recording(call, attachment)
    Call.transaction do
      attachment.file_attachment.update!(record: call, name: 'recording')
      call.update!(transcript: attachment.meta['transcribed_text'])
      # delete, not destroy: destroy would purge the file the call now holds
      attachment.delete
    end
  end
end
