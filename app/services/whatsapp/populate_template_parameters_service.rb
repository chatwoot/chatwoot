class Whatsapp::PopulateTemplateParametersService
  CHARACTER_CLASSES = Addressable::URI::CharacterClasses

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

  # `source` is what the API should fetch the media by: either `{ link: url }` or `{ id: media_id }`.
  def build_media_parameter(source, media_type, media_name = nil)
    source = { link: source } if source.is_a?(String)
    return nil if source[:link].blank? && source[:id].blank?

    source = { link: prepare_url(source[:link]) } if source[:id].blank?
    build_media_type_parameter(source, media_type.downcase, media_name)
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

  def build_media_type_parameter(source, media_type, media_name = nil)
    case media_type
    when 'image'
      { type: 'image', image: source }
    when 'video'
      { type: 'video', video: source }
    when 'document'
      { type: 'document', document: media_name.present? ? source.merge(filename: media_name) : source }
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

  def sanitize_parameter(value)
    # Basic sanitization - remove dangerous characters and limit length
    sanitized = value.to_s.strip
    sanitized = sanitized.gsub(/[<>\"']/, '') # Remove potential HTML/JS chars
    sanitized[0...1000] # Limit length to prevent DoS
  end

  # A URL is not free text, so it never goes through `sanitize_parameter`: that helper strips characters
  # and truncates at 1000 chars, which turns a long signed link into one that still looks valid but no
  # longer resolves. The Cloud API only reports that back as a generic "131053 Media upload error", with
  # no hint that we were the ones who broke the link.
  def prepare_url(url)
    normalized_url = normalize_url(url.to_s.strip)
    validate_url(normalized_url)
    normalized_url
  end

  # Percent-encodes only what is illegal in each component, leaving existing escapes untouched.
  #
  # `Addressable::URI#normalize` can't be used here because it *decodes* escaped octets that map back
  # to characters the component allows: `%3F` becomes a literal `?` that splits the query in two, which
  # invalidates a signed link such as the `header_handle` sample media a WhatsApp template ships with.
  # Encoding the URI as one string against the union of every reserved character is wrong in the other
  # direction: it leaves a bracket in the path unescaped, which `URI.parse` then rejects, and turns an
  # internationalized host into percent-encoded UTF-8 instead of punycode.
  def normalize_url(url)
    uri = Addressable::URI.parse(url)
    Addressable::URI.new(
      scheme: uri.scheme,
      userinfo: uri.userinfo,
      host: uri.normalized_host,
      port: uri.port,
      path: encode_uri_component(uri.path, CHARACTER_CLASSES::PATH),
      query: encode_uri_component(uri.query, CHARACTER_CLASSES::QUERY),
      fragment: encode_uri_component(uri.fragment, CHARACTER_CLASSES::FRAGMENT)
    ).to_s
  rescue Addressable::URI::InvalidURIError => e
    raise ArgumentError, "Invalid URL format: #{e.message}. Please enter a valid URL like https://example.com/document.pdf"
  end

  # `%` joins the class so escapes already present survive untouched instead of being double-encoded.
  # A `%` that does not start a valid escape is a literal one (`/100%.jpg`), and leaving it raw would
  # make `URI.parse` reject the whole URL, so it is escaped first.
  def encode_uri_component(value, character_class)
    return value if value.nil?

    Addressable::URI.encode_component(value.gsub(/%(?![0-9A-Fa-f]{2})/, '%25'), "#{character_class}%")
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
