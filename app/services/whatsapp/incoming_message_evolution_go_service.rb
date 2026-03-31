require 'base64'

class Whatsapp::IncomingMessageEvolutionGoService < Whatsapp::IncomingMessageBaseService
  private

  def processed_params
    @processed_params ||= params.with_indifferent_access
  end

  def download_attachment_file(attachment_payload)
    attachment = attachment_payload.with_indifferent_access
    return build_uploaded_file(attachment) if attachment[:base64].present?
    return Down.download(attachment[:media_url]) if attachment[:media_url].present?

    nil
  rescue StandardError => e
    Rails.logger.error "[EVOLUTION_GO] Attachment download failed: #{e.message}"
    nil
  end

  def build_uploaded_file(attachment)
    content = attachment[:base64].to_s
    encoded_payload = content.include?(',') ? content.split(',', 2).last : content

    tempfile = Tempfile.new(['evolution-go', file_extension_for(attachment)])
    tempfile.binmode
    tempfile.write(Base64.decode64(encoded_payload))
    tempfile.rewind

    filename = attachment[:filename].presence || "attachment#{file_extension_for(attachment)}"
    content_type = attachment[:mimetype].presence || 'application/octet-stream'

    tempfile.define_singleton_method(:original_filename) { filename }
    tempfile.define_singleton_method(:content_type) { content_type }
    tempfile
  end

  def file_extension_for(attachment)
    content_type = attachment[:mimetype].to_s
    return '.jpg' if content_type.start_with?('image/')
    return '.ogg' if content_type.start_with?('audio/')
    return '.mp4' if content_type.start_with?('video/')
    return File.extname(attachment[:filename].to_s) if attachment[:filename].present?

    '.bin'
  end
end
