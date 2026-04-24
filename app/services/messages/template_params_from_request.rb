class Messages::TemplateParamsFromRequest
  # Normalizes template_params from either nested multipart params or a single JSON field.
  def self.call(raw)
    return if raw.blank?

    normalized = if raw.is_a?(String)
                   JSON.parse(raw)
                 else
                   JSON.parse(raw.to_json)
                 end
    return normalized if normalized.is_a?(Hash) && normalized.present?

    nil
  rescue JSON::ParserError
    nil
  end
end
