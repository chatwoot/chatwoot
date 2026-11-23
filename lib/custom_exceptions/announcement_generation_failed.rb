class CustomExceptions::AnnouncementGenerationFailed < CustomExceptions::Base
  def message
    I18n.t('errors.voice.announcement_generation_failed')
  end

  def http_status
    502
  end
end
