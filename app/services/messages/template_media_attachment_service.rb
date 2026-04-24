class Messages::TemplateMediaAttachmentService
  include FileTypeHelper

  pattr_initialize [:message!, :attachments, :template_params]

  def perform
    media_blob_id = parsed_template_params.dig('processed_params', 'header', 'media_blob_id')
    return if media_blob_id.blank? || Array(attachments).include?(media_blob_id)

    attachment = message.attachments.build(
      account_id: message.account_id,
      file: media_blob_id
    )
    attachment.file_type = file_type_by_signed_id(media_blob_id)
  rescue ActiveSupport::MessageVerifier::InvalidSignature, ActiveRecord::RecordNotFound
    raise ArgumentError, 'Invalid media upload. Please upload the media again.'
  end

  private

  def parsed_template_params
    params_hash = template_params.is_a?(String) ? safe_parse_json(template_params) : template_params
    params_hash = params_hash.to_unsafe_h if params_hash.respond_to?(:to_unsafe_h)
    return {} unless params_hash.is_a?(Hash)

    params_hash.deep_stringify_keys
  end

  def safe_parse_json(value)
    JSON.parse(value)
  rescue JSON::ParserError
    {}
  end
end
