class Whatsapp::TemplateMediaResolverService
  pattr_initialize [:header_data!, :message]

  def call
    return header_data if media_blob_id.blank?
    raise ArgumentError, 'Provide either media URL or uploaded file, not both.' if header_data['media_url'].present?

    blob = ActiveStorage::Blob.find_signed!(media_blob_id)
    resolved_header_data.merge('media_url' => resolved_media_url(blob))
  rescue ActiveSupport::MessageVerifier::InvalidSignature, ActiveRecord::RecordNotFound
    raise ArgumentError, 'Invalid media upload. Please upload the media again.'
  end

  private

  def media_blob_id
    header_data['media_blob_id']
  end

  def resolved_header_data
    header_data.except('media_blob_id')
  end

  def resolved_media_url(blob)
    attachment = message&.attachments&.find { |item| item.file&.blob_id == blob.id }
    return attachment.download_url if attachment.present?

    ActiveStorage::Current.url_options = Rails.application.routes.default_url_options if ActiveStorage::Current.url_options.blank?
    blob.url
  end
end
