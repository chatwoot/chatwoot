class Whatsapp::PopulateTemplateParametersService
  def build_parameter(value)
    case value
    when String
      build_string_parameter(value)
    when Hash
      build_hash_parameter(value)
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

  def build_media_parameter(url, media_type)
    return nil if url.blank?

    sanitized_url = sanitize_parameter(url)
    validate_url(sanitized_url)
    build_media_type_parameter(sanitized_url, media_type.downcase)
  end

  def build_named_parameter(parameter_name, value)
    sanitized_value = sanitize_parameter(value.to_s)
    { type: 'text', parameter_name: parameter_name, text: sanitized_value }
  end

  private

  def build_string_parameter(value)
    sanitized_value = sanitize_parameter(value)
    if rich_formatting?(sanitized_value)
      build_rich_text_parameter(sanitized_value)
    else
      { type: 'text', text: sanitized_value }
    end
  end

  def build_hash_parameter(value)
    case value['type']
    when 'currency'
      build_currency_parameter(value)
    when 'date_time'
      build_date_time_parameter(value)
    else
      { type: 'text', text: value.to_s }
    end
  end

  def build_currency_parameter(value)
    {
      type: 'currency',
      currency: {
        fallback_value: value['fallback_value'],
        code: value['code'],
        amount_1000: value['amount_1000']
      }
    }
  end

  def build_date_time_parameter(value)
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
  end

  def build_media_type_parameter(sanitized_url, media_type)
    case media_type
    when 'image'
      build_image_parameter(sanitized_url)
    when 'video'
      build_video_parameter(sanitized_url)
    when 'document'
      build_document_parameter(sanitized_url)
    else
      raise ArgumentError, "Unsupported media type: #{media_type}"
    end
  end

  def build_image_parameter(url)
    { type: 'image', image: { link: url } }
  end

  def build_video_parameter(url)
    { type: 'video', video: { link: url } }
  end

  def build_document_parameter(url)
    { type: 'document', document: { link: url } }
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
end
