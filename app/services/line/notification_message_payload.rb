class Line::NotificationMessagePayload
  NOTIFICATION_TYPES = %w[template flexible].freeze

  def self.normalize(template_params)
    template_params = template_params.to_h if template_params.respond_to?(:to_h)
    template_params = template_params.stringify_keys if template_params.is_a?(Hash)
    template_params || {}
  end

  def self.valid?(template_params)
    params = normalize(template_params)
    type = params['type']

    return false unless type.in?(NOTIFICATION_TYPES)

    case type
    when 'template'
      params['template_key'].present?
    when 'flexible'
      params['messages'].present?
    else
      false
    end
  end
end
