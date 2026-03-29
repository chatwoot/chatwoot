class Schedulers::MessageBuilderService
  PLACEHOLDER_PATTERN = /\{\{(\w+)\}\}/

  def initialize(scheduler:, scheduled_message:)
    @scheduler = scheduler
    @scheduled_message = scheduled_message
  end

  def build
    template_params = @scheduler.template_params.deep_dup
    return template_params if template_params.blank?

    resolve_placeholders(template_params)
    template_params
  end

  private

  def resolve_placeholders(params)
    body = params.dig('processed_params', 'body')
    return unless body.is_a?(Hash)

    body.each do |key, value|
      next unless value.is_a?(String)

      body[key] = value.gsub(PLACEHOLDER_PATTERN) { |_match| resolve_value(Regexp.last_match(1)) }
    end
  end

  def resolve_value(placeholder)
    case placeholder
    when 'customer_name'
      @scheduled_message.contact&.name.presence || @scheduled_message.customer_name || ''
    when 'customer_phone'
      @scheduled_message.customer_phone || ''
    when 'scheduled_at'
      @scheduled_message.scheduled_at&.strftime('%Y-%m-%d %H:%M') || ''
    when 'appointment_date'
      @scheduled_message.metadata&.dig('appointment_date') || @scheduled_message.scheduled_at&.strftime('%Y-%m-%d') || ''
    when 'appointment_time'
      @scheduled_message.metadata&.dig('appointment_time') || @scheduled_message.scheduled_at&.strftime('%H:%M') || ''
    else
      @scheduled_message.metadata&.dig(placeholder) || ''
    end
  end
end
