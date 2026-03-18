Rails.application.config.active_storage.service_urls_expire_in = 1.year

module AttachmentUrlPatch
  def file_url
    return '' unless file.attached?

    ActiveStorage::Current.url_options = Rails.application.routes.default_url_options if ActiveStorage::Current.url_options.blank?
    file.blob.url(expires_in: ActiveStorage.service_urls_expire_in)
  end

  def thumb_url
    return '' unless file.attached? && image?

    ActiveStorage::Current.url_options = Rails.application.routes.default_url_options if ActiveStorage::Current.url_options.blank?
    file.blob.url(expires_in: ActiveStorage.service_urls_expire_in)
  rescue StandardError => e
    Rails.logger.warn "thumb_url error for attachment #{id}: #{e.message}"
    ''
  end
end

Rails.application.config.to_prepare do
  Attachment.prepend(AttachmentUrlPatch)
end
