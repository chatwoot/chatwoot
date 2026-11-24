# The attachment a session message gets from the bytes its provider handed over. Shared by
# the writer, which attaches before the first save when the backend downloads inline, and
# MediaFetchJob, which attaches afterwards, so both store the same file under the same name.
module Whatsapp::Session::Inbound::MediaAttachment
  # The writer runs under the message and chat locks (30 seconds each): a download that
  # outlived them would let a redelivery of the same message in beside it.
  INLINE_TIMEOUT = 10.seconds

  # Attaches the file before the message's first save, for a backend that downloads inline.
  # Any failure leaves the message without it, and the fetch queued after the save collects
  # it as it always did.
  def self.download(message, inbound)
    media = Whatsapp::Session::Inbound::MessageWriter.media_in(inbound)
    return if media.nil? || media.ref.blank?

    backend = message.inbox.channel.session_backend
    return unless backend.class.inline_media?

    command = Whatsapp::Session::Model::Commands::MessageDownloadMedia.new(chat: inbound.chat, message_id: message.source_id,
                                                                           ref: media.ref)
    payload = ::Timeout.timeout(INLINE_TIMEOUT) { backend.download_media(command) }
    build(message, media, payload)
  rescue ::Timeout::Error, Whatsapp::Session::Errors::Error => e
    Rails.logger.warn("[WHATSAPP SESSION] inline media download failed for #{message.source_id}, left to the fetch job: #{e.message}")
  end

  def self.build(message, media, payload)
    attachment = message.attachments.build(
      account_id: message.account_id,
      file_type: media.attachment_file_type,
      file: { io: payload.io, filename: filename(media, payload, message), content_type: payload.mime || media.mime }
    )
    attachment.meta = { is_recorded_audio: true } if media.voice_note
    attachment.meta = { is_video_note: true } if media.video_note
    attachment
  end

  def self.filename(media, payload, message)
    return media.filename if media.filename.present?
    return payload.filename if payload.filename.present?

    mime = (payload.mime || media.mime).to_s
    extension = ".#{mime.split(';').first.split('/').last}" if mime.present?
    "#{media.kind}_#{message.source_id}_#{Time.current.strftime('%Y%m%d')}#{extension}"
  end
end
