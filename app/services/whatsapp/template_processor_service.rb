class Whatsapp::TemplateProcessorService
  pattr_initialize [:channel!, :template_params, :message]

  def call
    if template_params.present?
      process_template_with_params
    else
      process_template_from_message
    end
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

  def process_template_from_message
    return [nil, nil, nil, nil] if message.blank?

    # Delete the following logic once the update for template_params is stable
    # see if we can match the message content to a template
    # An example template may look like "Your package has been shipped. It will be delivered in {{1}} business days.
    # We want to iterate over these templates with our message body and see if we can fit it to any of the templates
    # Then we use regex to parse the template varibles and convert them into the proper payload
    channel.message_templates&.each do |template|
      match_obj = template_match_object(template)
      next if match_obj.blank?

      # we have a match, now we need to parse the template variables and convert them into the wa recommended format
      processed_parameters = match_obj.captures.map { |x| { type: 'text', text: x } }

      # no need to look up further end the search
      return [template['name'], template['namespace'], template['language'], processed_parameters]
    end
    [nil, nil, nil, nil]
  end

  def template_match_object(template)
    body_object = validated_body_object(template)
    return if body_object.blank?

    template_match_regex = build_template_match_regex(body_object['text'])
    message.outgoing_content.match(template_match_regex)
  end

  def build_template_match_regex(template_text)
    # Converts the whatsapp template to a comparable regex string to check against the message content
    # the variables are of the format {{num}} ex:{{1}}

    # transform the template text into a regex string
    # we need to replace the {{num}} with matchers that can be used to capture the variables
    template_text = template_text.gsub(/{{\d}}/, '(.*)')
    # escape if there are regex characters in the template text
    template_text = Regexp.escape(template_text)
    # ensuring only the variables remain as capture groups
    template_text = template_text.gsub(Regexp.escape('(.*)'), '(.*)')

    template_match_string = "^#{template_text}$"
    Regexp.new template_match_string
  end

  def find_template
    channel.message_templates.find do |t|
      t['name'] == template_params['name'] && t['language'] == template_params['language'] && t['status']&.downcase == 'approved'
    end
  end

  def processed_templates_params
    template = find_template
    return if template.blank?

    # Handle enhanced template parameters structure
    if template_params['processed_params'].is_a?(Hash) && template_params['processed_params'].key?('body')
      process_enhanced_template_params(template)
    else
      # Legacy processing for backward compatibility
      process_legacy_template_params(template)
    end
  end

  def process_enhanced_template_params(_template)
    processed_params = template_params['processed_params']
    components = []

    # Process body parameters
    if processed_params['body'].present?
      body_params = processed_params['body'].map { |_, value| build_parameter(value) }
      components << { type: 'body', parameters: body_params }
    end

    # Process header parameters
    if processed_params['header'].present?
      header_params = processed_params['header'].filter_map do |key, value|
        if key == 'media_url' && processed_params['header']['media_type'].present?
          build_media_parameter(value, processed_params['header']['media_type'])
        else
          build_parameter(value)
        end
      end

      # Only add header component if we have valid parameters
      components << { type: 'header', parameters: header_params } if header_params.present?
    end

    # Process footer parameters (rarely used but supported)
    if processed_params['footer'].present?
      footer_params = processed_params['footer'].map { |_, value| build_parameter(value) }
      components << { type: 'footer', parameters: footer_params }
    end

    # Process button parameters
    if processed_params['buttons'].present?
      button_params = processed_params['buttons'].map.with_index do |button, index|
        {
          type: 'button',
          sub_type: button['type'] || 'url',
          index: index,
          parameters: [build_button_parameter(button)]
        }
      end
      components.concat(button_params)
    end

    components
  end

  def process_legacy_template_params(template)
    parameter_format = template['parameter_format']

    if parameter_format == 'NAMED'
      template_params['processed_params']&.map { |key, value| { type: 'text', parameter_name: key, text: value } }
    else
      template_params['processed_params']&.map { |_, value| { type: 'text', text: value } }
    end
  end

  def build_parameter(value)
    case value
    when String
      sanitized_value = sanitize_parameter(value)
      if sanitized_value.match?(%r{^https?://})
        validate_url(sanitized_value)
        # URL parameter (for media or documents)
        { type: 'image', image: { link: sanitized_value } }
      else
        # Text parameter
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
      when 'location'
        {
          type: 'location',
          location: {
            latitude: value['latitude'],
            longitude: value['longitude'],
            name: value['name'],
            address: value['address']
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
      build_parameter(button['parameter'])
    end
  end

  def sanitize_parameter(value)
    # Basic sanitization - remove dangerous characters and limit length
    sanitized = value.to_s.strip
    sanitized = sanitized.gsub(/[<>\"']/, '') # Remove potential HTML/JS chars
    sanitized[0...1000] # Limit length to prevent DoS
  end

  def validate_url(url)
    uri = URI.parse(url)
    raise ArgumentError, 'Invalid URL scheme' unless %w[http https].include?(uri.scheme)
    raise ArgumentError, 'URL too long' if url.length > 2000
  rescue URI::InvalidURIError
    raise ArgumentError, 'Invalid URL format'
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

  def validated_body_object(template)
    # we don't care if its not approved template
    return if template['status'] != 'approved'

    # we only care about text body object in template. if not present we discard the template
    # we don't support other forms of templates
    template['components'].find { |obj| obj['type'] == 'BODY' && obj.key?('text') }
  end
end
