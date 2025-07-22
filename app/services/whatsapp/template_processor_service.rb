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
    if template_params['processed_params'].is_a?(Hash) &&
       (template_params['processed_params'].key?('body') || template_params['processed_params'].key?('buttons'))
      process_enhanced_template_params(template)
    else
      # Check if we have special header types that need processing
      header_component = template['components'].find { |c| c['type'] == 'HEADER' }
      if header_component&.dig('format')&.in?(%w[IMAGE VIDEO DOCUMENT])
        process_media_template_params(template, header_component)
      elsif template['category']&.downcase == 'authentication'
        process_authentication_template_params(template)
      else
        process_legacy_template_params(template)
      end
    end
  end

  def process_media_template_params(_template, header_component)
    # For templates with media headers, we need to create proper component parameters
    components = []

    # Add header component with media parameter
    media_url = if header_component['example'] && header_component['example']['header_handle']
                  # Template has example media URL, use it as a placeholder
                  header_component['example']['header_handle'].first
                else
                  # No example, need to provide a media URL parameter
                  # Since we don't have user input, we'll create an empty media parameter
                  'https://example.com/placeholder.jpg' # Placeholder URL
                end

    components << {
      type: 'header',
      parameters: [{
        :type => header_component['format'].downcase,
        header_component['format'].downcase => {
          link: media_url
        }
      }]
    }

    # Add body parameters if any
    body_params = template_params['processed_params'].map { |_, value| { type: 'text', text: value } }
    components << { type: 'body', parameters: body_params } if body_params.present?

    @template_params = components
  end

  def process_authentication_template_params(_template)
    # Authentication templates typically have OTP codes and expiration times
    components = []

    # Process body parameters for authentication templates
    if template_params['processed_params'].present?
      body_params = if template_params['processed_params'].is_a?(Hash)
                      process_authentication_body_params(template_params['processed_params'])
                    else
                      template_params['processed_params'].map { |_, value| { type: 'text', text: value } }
                    end
      components << { type: 'body', parameters: body_params } if body_params.present?
    end

    @template_params = components
  end

  def process_enhanced_template_params(_template)
    processed_params = template_params['processed_params']
    Rails.logger.info "DEBUG: Raw processed_params from frontend: #{processed_params.inspect}"
    components = []

    # Process header parameters first (important for WhatsApp API order)
    if processed_params['header'].present?
      header_params = []

      processed_params['header'].each do |key, value|
        next if value.blank?

        if key == 'media_url' && processed_params['header']['media_type'].present?
          media_param = build_media_parameter(value, processed_params['header']['media_type'])
          header_params << media_param if media_param
        elsif key != 'media_type'
          header_params << build_parameter(value)
        end
      end

      # Only add header component if we have valid parameters
      components << { type: 'header', parameters: header_params } if header_params.present?
    end

    # Process body parameters
    if processed_params['body'].present?
      body_params = processed_params['body'].filter_map do |key, value|
        next if value.blank?

        # Handle special authentication parameters
        if key == 'otp_code'
          build_authentication_parameter(value, 'otp')
        elsif key == 'expiry_minutes'
          build_authentication_parameter(value, 'expiry')
        else
          build_parameter(value)
        end
      end
      components << { type: 'body', parameters: body_params } if body_params.present?
    end

    # Process footer parameters (rarely used but supported)
    if processed_params['footer'].present?
      footer_params = processed_params['footer'].filter_map do |_, value|
        next if value.blank?

        build_parameter(value)
      end
      components << { type: 'footer', parameters: footer_params } if footer_params.present?
    end

    # Process button parameters
    if processed_params['buttons'].present?
      button_params = processed_params['buttons'].filter_map.with_index do |button, index|
        next if button.blank?

        # For URL buttons, parameter is required even if blank
        if button['type'] == 'url' || button['parameter'].present?
          button_component = {
            type: 'button',
            sub_type: button['type'] || 'url',
            index: index,
            parameters: [build_button_parameter(button)]
          }
          Rails.logger.info "DEBUG: Button component created: #{button_component.inspect}"
          button_component
        end
      end
      components.concat(button_params) if button_params.present?
    end

    Rails.logger.info "DEBUG: Final components being sent to WhatsApp API: #{components.inspect}"
    @template_params = components
  end

  def process_legacy_template_params(template)
    parameter_format = template['parameter_format']

    @template_params = if parameter_format == 'NAMED'
                         template_params['processed_params']&.map { |key, value| { type: 'text', parameter_name: key, text: value } }
                       else
                         template_params['processed_params']&.map { |_, value| { type: 'text', text: value } }
                       end
    @template_params
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
    Rails.logger.info "DEBUG: Processing button parameter: #{button.inspect}"
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
      param_result = { type: 'text', text: button['parameter'].to_s.strip }
      Rails.logger.info "DEBUG: Button parameter result: #{param_result.inspect}"
      param_result
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
    raise ArgumentError, "Invalid URL format: #{e.message}. Please enter a valid image URL like https://example.com/image.jpg"
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

  def build_authentication_parameter(value, param_type)
    # Authentication-specific parameters
    sanitized_value = sanitize_parameter(value)

    case param_type
    when 'otp'
      # OTP code - typically 4-8 digits
      raise ArgumentError, 'OTP code must be numeric' unless sanitized_value.match?(/\A\d+\z/)
      raise ArgumentError, 'OTP code must be 4-8 digits' unless sanitized_value.length.between?(4, 8)

      { type: 'text', text: sanitized_value }
    when 'expiry'
      # Expiry time in minutes
      expiry_minutes = sanitized_value.to_i
      raise ArgumentError, 'Expiry minutes must be a positive number' unless expiry_minutes.positive?

      { type: 'text', text: expiry_minutes.to_s }
    else
      { type: 'text', text: sanitized_value }
    end
  end

  def process_authentication_body_params(processed_params)
    # Process authentication-specific body parameters
    processed_params.filter_map do |key, value|
      next if value.blank?

      case key
      when 'otp_code'
        build_authentication_parameter(value, 'otp')
      when 'expiry_minutes'
        build_authentication_parameter(value, 'expiry')
      else
        build_parameter(value)
      end
    end
  end

  def validated_body_object(template)
    # we don't care if its not approved template
    return if template['status'] != 'approved'

    # we only care about text body object in template. if not present we discard the template
    # we don't support other forms of templates
    template['components'].find { |obj| obj['type'] == 'BODY' && obj.key?('text') }
  end

  def process_dynamic_button_text(button_text, button_index)
    return button_text unless button_text.include?('{{')

    # Replace button text variables with provided parameters
    if template_params['processed_params'].present?
      button_params = template_params['processed_params']['buttons']
      if button_params.is_a?(Array) && button_params[button_index].present?
        button_param = button_params[button_index]['parameter'] || button_params[button_index]['text']
        if button_param.present?
          # Replace {{1}}, {{variable}}, etc. with the provided parameter
          button_text = button_text.gsub(/\{\{[^}]+\}\}/, button_param.to_s)
        end
      end
    end

    button_text
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
end
