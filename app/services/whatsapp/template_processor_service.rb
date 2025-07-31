class Whatsapp::TemplateProcessorService
  pattr_initialize [:channel!, :template_params, :message]

  def call
    return [nil, nil, nil, nil] if template_params.blank?

    process_template_with_params
  end

  private

  def process_template_with_params
    [
      template_params['name'],
      template_params['namespace'],
      template_params['language'],
      processed_templates_params
    ]
  end

  def find_template
    channel.message_templates.find do |t|
      t['name'] == template_params['name'] && t['language'] == template_params['language'] && t['status']&.downcase == 'approved'
    end
  end

  def processed_templates_params
    template = find_template
    return if template.blank?

    process_enhanced_template_params(template)
  end

  def process_enhanced_template_params(template)
    processed_params = template_params['processed_params']
    components = []

    components.concat(process_header_components(processed_params))
    components.concat(process_body_components(processed_params, template))
    components.concat(process_footer_components(processed_params))
    components.concat(process_button_components(processed_params))

    @template_params = components
  end

  def process_header_components(processed_params)
    return [] unless processed_params['header'].present?

    header_params = []
    processed_params['header'].each do |key, value|
      next if value.blank?

      if key == 'media_url' && processed_params['header']['media_type'].present?
        media_type = processed_params['header']['media_type']
        media_param = build_media_parameter(value, media_type)
        header_params << media_param if media_param
      elsif key != 'media_type'
        header_params << build_parameter(value)
      end
    end

    header_params.present? ? [{ type: 'header', parameters: header_params }] : []
  end

  def process_body_components(processed_params, template)
    return [] unless processed_params['body'].present?

    body_params = processed_params['body'].filter_map do |key, value|
      next if value.blank?

      parameter_format = template['parameter_format']
      if parameter_format == 'NAMED'
        build_named_parameter(key, value)
      else
        build_parameter(value)
      end
    end

    body_params.present? ? [{ type: 'body', parameters: body_params }] : []
  end

  def process_footer_components(processed_params)
    return [] unless processed_params['footer'].present?

    footer_params = processed_params['footer'].filter_map do |_, value|
      next if value.blank?

      build_parameter(value)
    end

    footer_params.present? ? [{ type: 'footer', parameters: footer_params }] : []
  end

  def process_button_components(processed_params)
    return [] unless processed_params['buttons'].present?

    button_params = processed_params['buttons'].filter_map.with_index do |button, index|
      next if button.blank?

      if button['type'] == 'url' || button['parameter'].present?
        {
          type: 'button',
          sub_type: button['type'] || 'url',
          index: index,
          parameters: [build_button_parameter(button)]
        }
      end
    end

    button_params.compact
  end

  def build_parameter(value)
    case value
    when String
      sanitized_value = sanitize_parameter(value)
      # Check if this is rich text formatting
      if rich_formatting?(sanitized_value)
        build_rich_text_parameter(sanitized_value)
      else
        # For regular template parameters, always treat as text
        # Media parameters are handled separately via build_media_parameter
        { type: 'text', text: sanitized_value }
      end
    when Hash
      # Advanced parameter types
      case value['type']
      when 'currency'
        {
          type: 'currency',
          currency: {
            fallback_value: value['fallback_value'],
            code: value['code'],
            amount_1000: value['amount_1000']
          }
        }
      when 'date_time'
        {
          type: 'date_time',
          date_time: {
            fallback_value: value['fallback_value'],
            day_of_week: value['day_of_week'],
            day_of_month: value['day_of_month'],
            month: value['month'],
            year: value['year']
          }
        }
      else
        { type: 'text', text: value.to_s }
      end
    else
      { type: 'text', text: value.to_s }
    end
  end

  def build_button_parameter(button)
    return { type: 'text', text: '' } if button.blank?

    case button['type']
    when 'copy_code'
      coupon_code = button['parameter'].to_s.strip
      raise ArgumentError, 'Coupon code cannot be empty' if coupon_code.blank?
      raise ArgumentError, 'Coupon code cannot exceed 15 characters' if coupon_code.length > 15

      {
        type: 'coupon_code',
        coupon_code: coupon_code
      }
    else
      # For URL buttons and other button types, treat parameter as text
      # If parameter is blank, use empty string (required for URL buttons)
      { type: 'text', text: button['parameter'].to_s.strip }
    end
  end

  def sanitize_parameter(value)
    # Basic sanitization - remove dangerous characters and limit length
    sanitized = value.to_s.strip
    sanitized = sanitized.gsub(/[<>\"']/, '') # Remove potential HTML/JS chars
    sanitized[0...1000] # Limit length to prevent DoS
  end

  def validate_url(url)
    return if url.blank?

    uri = URI.parse(url)
    raise ArgumentError, "Invalid URL scheme: #{uri.scheme}. Only http and https are allowed" unless %w[http https].include?(uri.scheme)
    raise ArgumentError, 'URL too long (max 2000 characters)' if url.length > 2000

  rescue URI::InvalidURIError => e
    raise ArgumentError, "Invalid URL format: #{e.message}. Please enter a valid URL like https://example.com/document.pdf"
  end

  def build_media_parameter(url, media_type)
    return nil if url.blank?

    sanitized_url = sanitize_parameter(url)
    validate_url(sanitized_url)

    case media_type.downcase
    when 'image'
      {
        type: 'image',
        image: {
          link: sanitized_url
        }
      }
    when 'video'
      {
        type: 'video',
        video: {
          link: sanitized_url
        }
      }
    when 'document'
      {
        type: 'document',
        document: {
          link: sanitized_url
        }
      }
    else
      raise ArgumentError, "Unsupported media type: #{media_type}"
    end
  end

  def rich_formatting?(text)
    # Check if text contains WhatsApp rich formatting markers
    text.match?(/\*[^*]+\*/) || # Bold: *text*
      text.match?(/_[^_]+_/) ||   # Italic: _text_
      text.match?(/~[^~]+~/) ||   # Strikethrough: ~text~
      text.match?(/```[^`]+```/) # Monospace: ```text```
  end

  def build_rich_text_parameter(text)
    # WhatsApp supports rich text formatting in templates
    # This preserves the formatting markers for the API
    { type: 'text', text: text }
  end

  def build_named_parameter(parameter_name, value)
    sanitized_value = sanitize_parameter(value.to_s)
    { type: 'text', parameter_name: parameter_name, text: sanitized_value }
  end
end
