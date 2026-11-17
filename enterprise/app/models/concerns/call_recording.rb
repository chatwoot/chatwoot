# Where a call's recording and transcript live: on the call for Twilio, which downloads the recording itself, and on
# the call's message for WhatsApp, whose recording the agent's browser uploads as an audio attachment.
module Concerns::CallRecording
  extend ActiveSupport::Concern

  included do
    has_one_attached :recording
  end

  def recording_url
    return whatsapp_recording_url if whatsapp?
    return nil unless recording.attached?

    Rails.application.routes.url_helpers.rails_blob_url(recording)
  end

  def recording_transcript
    return whatsapp_recording_attachment&.meta&.dig('transcribed_text').presence if whatsapp?

    transcript
  end

  private

  # Searched in Ruby so a preloaded calls list stays query-free
  def whatsapp_recording_attachment
    message&.attachments&.find { |attachment| attachment.audio? && attachment.file.attached? }
  end

  def whatsapp_recording_url
    attachment = whatsapp_recording_attachment
    return nil if attachment.blank?

    Rails.application.routes.url_helpers.rails_blob_url(attachment.file)
  end
end
