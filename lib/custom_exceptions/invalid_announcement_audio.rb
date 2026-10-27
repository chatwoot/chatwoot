class CustomExceptions::InvalidAnnouncementAudio < CustomExceptions::Base
  def message
    I18n.t('errors.voice.announcement_audio_mismatch')
  end

  def http_status
    502
  end
end
