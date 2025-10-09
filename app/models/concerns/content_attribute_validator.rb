class ContentAttributeValidator < ActiveModel::Validator
  ALLOWED_SELECT_ITEM_KEYS = [:title, :value].freeze
  ALLOWED_CARD_ITEM_KEYS = [:title, :description, :media_url, :actions].freeze
  ALLOWED_CARD_ITEM_ACTION_KEYS = [:text, :type, :payload, :uri].freeze
  ALLOWED_FORM_ITEM_KEYS = [:type, :placeholder, :label, :name, :options, :default, :required, :pattern, :title, :pattern_error].freeze
  ALLOWED_ARTICLE_KEYS = [:title, :description, :link].freeze

  # Apple Messages for Business validation keys
  ALLOWED_APPLE_LIST_PICKER_KEYS = [:sections, :images, :received_title, :received_subtitle, :received_image_identifier, :received_style,
                                    :reply_title, :reply_subtitle, :reply_image_title, :reply_image_subtitle, :reply_secondary_subtitle, :reply_tertiary_subtitle, :reply_image_identifier, :reply_style].freeze
  ALLOWED_APPLE_LIST_PICKER_SECTION_KEYS = [:title, :multiple_selection, :multipleSelection, :order, :items].freeze
  ALLOWED_APPLE_LIST_PICKER_ITEM_KEYS = [:identifier, :title, :subtitle, :image_identifier, :imageIdentifier, :order, :style].freeze
  ALLOWED_APPLE_TIME_PICKER_KEYS = [:event, :timezone_offset, :timeslots, :received_title, :received_subtitle, :received_image_identifier,
                                    :received_style, :reply_title, :reply_subtitle, :reply_image_title, :reply_image_subtitle, :reply_secondary_subtitle, :reply_tertiary_subtitle, :reply_image_identifier, :reply_style].freeze
  ALLOWED_APPLE_QUICK_REPLY_KEYS = [:summary_text, :items, :received_title, :received_subtitle, :received_style,
                                    :reply_title, :reply_subtitle, :reply_style, :reply_image_title, :reply_image_subtitle,
                                    :reply_secondary_subtitle, :reply_tertiary_subtitle].freeze
  ALLOWED_APPLE_QUICK_REPLY_ITEM_KEYS = [:identifier, :title].freeze
  ALLOWED_APPLE_IMAGE_KEYS = [:identifier, :data, :description].freeze
  ALLOWED_APPLE_RICH_LINK_KEYS = [:url, :title, :description, :image_data, :image_mime_type, :video_url, :video_mime_type, :site_name].freeze
  ALLOWED_APPLE_PAY_KEYS = [:payment_request, :merchant_session, :endpoints].freeze
  ALLOWED_APPLE_AUTHENTICATION_KEYS = [:oauth2, :response_encryption_key, :state, :redirect_uri].freeze
  ALLOWED_APPLE_FORM_KEYS = [:title, :description, :fields, :pages, :submit_url, :method, :validation_rules, :images, :received_message, :reply_message].freeze
  ALLOWED_APPLE_CUSTOM_APP_KEYS = [:app_id, :app_name, :bid, :url, :use_live_layout].freeze

  # Apple MSP style values
  APPLE_STYLE_VALUES = %w[icon small large].freeze

  def validate(record)
    case record.content_type
    when 'input_select'
      validate_items!(record)
      validate_item_attributes!(record, ALLOWED_SELECT_ITEM_KEYS)
    when 'cards'
      validate_items!(record)
      validate_item_attributes!(record, ALLOWED_CARD_ITEM_KEYS)
      validate_item_actions!(record)
    when 'form'
      validate_items!(record)
      validate_item_attributes!(record, ALLOWED_FORM_ITEM_KEYS)
    when 'article'
      validate_items!(record)
      validate_item_attributes!(record, ALLOWED_ARTICLE_KEYS)
    when 'apple_list_picker'
      auto_generate_apple_identifiers!(record)
      validate_apple_list_picker!(record)
    when 'apple_time_picker'
      auto_generate_apple_identifiers!(record)
      validate_apple_time_picker!(record)
    when 'apple_quick_reply'
      auto_generate_apple_identifiers!(record)
      validate_apple_quick_reply!(record)
    when 'apple_rich_link'
      validate_apple_rich_link!(record)
    when 'apple_pay'
      validate_apple_pay!(record)
    when 'apple_authentication'
      validate_apple_authentication!(record)
    when 'apple_form'
      validate_apple_form!(record)
    when 'apple_custom_app'
      validate_apple_custom_app!(record)
    end
  end

  private

  def validate_items!(record)
    record.errors.add(:content_attributes, 'At least one item is required.') if record.items.blank?
    record.errors.add(:content_attributes, 'Items should be a hash.') if record.items.reject { |item| item.is_a?(Hash) }.present?
  end

  def validate_item_attributes!(record, valid_keys)
    item_keys = record.items.collect(&:keys).flatten.filter_map(&:to_sym)
    invalid_keys = item_keys - valid_keys
    record.errors.add(:content_attributes, "contains invalid keys for items : #{invalid_keys}") if invalid_keys.present?
  end

  def validate_item_actions!(record)
    if record.items.select { |item| item[:actions].blank? }.present?
      record.errors.add(:content_attributes, 'contains items missing actions') && return
    end

    validate_item_action_attributes!(record)
  end

  def validate_item_action_attributes!(record)
    item_action_keys = record.items.collect { |item| item[:actions].collect(&:keys) }
    invalid_keys = item_action_keys.flatten.compact.map(&:to_sym) - ALLOWED_CARD_ITEM_ACTION_KEYS
    record.errors.add(:content_attributes, "contains invalid keys for actions:  #{invalid_keys}") if invalid_keys.present?
  end

  # Apple Messages for Business identifier auto-generation and structure normalization
  def auto_generate_apple_identifiers!(record)
    content_attrs = record.content_attributes || {}

    # 🔥 DEBUG: Log what we receive
    if record.content_type&.start_with?('apple_')
      Rails.logger.info "🔥 ContentAttributeValidator - Processing #{record.content_type}"
      Rails.logger.info "🔥 ContentAttributeValidator - Input content_attrs: #{content_attrs.inspect}"
      Rails.logger.info "🔥 ContentAttributeValidator - Images present: #{content_attrs['images']&.length || 0}"
    end

    case record.content_type
    when 'apple_list_picker'
      # Normalize list picker structure for Apple MSP
      sections = content_attrs['sections'] || []
      sections.each do |section|
        next unless section.is_a?(Hash)

        # Ensure multipleSelection is properly named (Apple uses camelCase)
        section['multipleSelection'] = section.delete('multiple_selection') if section.key?('multiple_selection')

        items = section['items'] || []
        items.each do |item|
          next unless item.is_a?(Hash)

          # Auto-generate identifier if not present (platform-generated, not agent-exposed)
          item['identifier'] ||= "item_#{SecureRandom.hex(8)}"

          # Normalize imageIdentifier field (Apple uses camelCase)
          item['imageIdentifier'] = item.delete('image_identifier') if item.key?('image_identifier')

          # Set default style if not present (use valid Apple MSP style)
          item['style'] ||= 'icon'
        end
      end

      # Auto-generate image identifiers if images are present
      images = content_attrs['images'] || []
      images.each do |image|
        next unless image.is_a?(Hash)

        image['identifier'] ||= "img_#{SecureRandom.hex(8)}"
      end

      # Add default received/reply message structure if not present
      content_attrs['received_title'] ||= content_attrs['receivedTitle'] || record.content || 'Please select an option'
      content_attrs['received_subtitle'] ||= content_attrs['receivedSubtitle'] || ''
      content_attrs['received_style'] ||= validate_style_value(content_attrs['received_style']) || 'icon'
      content_attrs['reply_title'] ||= 'Selection Made'
      content_attrs['reply_subtitle'] ||= 'Your selection'
      content_attrs['reply_style'] ||= validate_style_value(content_attrs['reply_style']) || 'icon'

    when 'apple_quick_reply'
      items = content_attrs['items'] || []
      items.each do |item|
        next unless item.is_a?(Hash)

        # Auto-generate identifier if not present (platform-generated, not agent-exposed)
        item['identifier'] ||= "reply_#{SecureRandom.hex(8)}"
      end

      # Ensure summaryText is present
      content_attrs['summary_text'] ||= content_attrs['summaryText'] || record.content || 'Please select an option'

    when 'apple_time_picker'
      # Normalize time picker structure
      event = content_attrs['event'] || {}

      # Ensure timeslots are in the event structure for Apple MSP
      if content_attrs['timeslots'] && !event['timeslots']
        event['timeslots'] = content_attrs['timeslots']
        content_attrs.delete('timeslots') # Remove from top level
      end

      timeslots = event['timeslots'] || []
      timeslots.each do |slot|
        next unless slot.is_a?(Hash)

        # Auto-generate identifier if not present (platform-generated, not agent-exposed)
        slot['identifier'] ||= SecureRandom.hex(1) # Use simple numeric-like identifier
      end

      # Ensure timezone offset is properly named
      if content_attrs['timezone_offset'] && !event['timezoneOffset']
        event['timezoneOffset'] = content_attrs['timezone_offset']
        content_attrs.delete('timezone_offset') # Remove from top level
      end

      # Apple MSP requires specific event structure
      event['identifier'] ||= '1' # Apple sample uses "1"
      event['title'] = '' # Apple sample uses empty string for title

      content_attrs['event'] = event

      # Add default received/reply message structure if not present
      content_attrs['received_title'] ||= event['title'] || record.content || 'Select a time'
      content_attrs['received_subtitle'] ||= event['description'] || ''
      content_attrs['received_style'] ||= validate_style_value(content_attrs['received_style']) || 'icon'
      content_attrs['reply_title'] ||= 'Appointment Scheduled'
      # NOTE: Apple time picker samples do not include reply_subtitle, so we don't set a default
      content_attrs['reply_style'] ||= validate_style_value(content_attrs['reply_style']) || 'icon'
    end

    # Update the record's content_attributes with the generated identifiers and normalized structure
    record.content_attributes = content_attrs
  end

  # Validate Apple MSP style values
  def validate_style_value(style)
    return style if style.nil? || APPLE_STYLE_VALUES.include?(style)

    'icon' # Default fallback
  end

  # Apple Messages for Business validation methods
  def validate_apple_list_picker!(record)
    content_attrs = record.content_attributes || {}

    # Skip validation for incoming interactive messages (they contain interactive_data)
    # These are validated by Apple and we just store the response
    return if content_attrs['interactive_data'].present?

    # Validate top-level keys
    invalid_keys = content_attrs.keys.map(&:to_sym) - ALLOWED_APPLE_LIST_PICKER_KEYS
    record.errors.add(:content_attributes, "contains invalid keys for apple_list_picker: #{invalid_keys}") if invalid_keys.present?

    # Validate sections
    sections = content_attrs['sections'] || []
    record.errors.add(:content_attributes, 'sections is required for apple_list_picker') if sections.blank?

    sections.each_with_index do |section, index|
      next unless section.is_a?(Hash)

      invalid_section_keys = section.keys.map(&:to_sym) - ALLOWED_APPLE_LIST_PICKER_SECTION_KEYS
      record.errors.add(:content_attributes, "section #{index} contains invalid keys: #{invalid_section_keys}") if invalid_section_keys.present?

      # Validate section items
      items = section['items'] || []
      items.each_with_index do |item, item_index|
        next unless item.is_a?(Hash)

        invalid_item_keys = item.keys.map(&:to_sym) - ALLOWED_APPLE_LIST_PICKER_ITEM_KEYS
        if invalid_item_keys.present?
          record.errors.add(:content_attributes,
                            "section #{index} item #{item_index} contains invalid keys: #{invalid_item_keys}")
        end

        # Validate style value if present
        if item['style'] && !APPLE_STYLE_VALUES.include?(item['style'])
          record.errors.add(:content_attributes,
                            "section #{index} item #{item_index} has invalid style value: #{item['style']}. Must be one of: #{APPLE_STYLE_VALUES.join(', ')}")
        end
      end
    end

    # Validate images if present
    images = content_attrs['images'] || []
    images.each_with_index do |image, index|
      next unless image.is_a?(Hash)

      invalid_image_keys = image.keys.map(&:to_sym) - ALLOWED_APPLE_IMAGE_KEYS
      record.errors.add(:content_attributes, "image #{index} contains invalid keys: #{invalid_image_keys}") if invalid_image_keys.present?

      record.errors.add(:content_attributes, "image #{index} missing identifier") if image['identifier'].blank?
      record.errors.add(:content_attributes, "image #{index} missing data") if image['data'].blank?
    end

    # Validate style values for received and reply messages
    %w[received_style reply_style].each do |style_field|
      style_value = content_attrs[style_field]
      if style_value && !APPLE_STYLE_VALUES.include?(style_value)
        record.errors.add(:content_attributes, "#{style_field} has invalid value: #{style_value}. Must be one of: #{APPLE_STYLE_VALUES.join(', ')}")
      end
    end
  end

  def validate_apple_time_picker!(record)
    content_attrs = record.content_attributes || {}

    # Skip validation for incoming interactive messages (they contain interactive_data)
    # These are validated by Apple and we just store the response
    return if content_attrs['interactive_data'].present?

    # Validate top-level keys
    invalid_keys = content_attrs.keys.map(&:to_sym) - ALLOWED_APPLE_TIME_PICKER_KEYS
    record.errors.add(:content_attributes, "contains invalid keys for apple_time_picker: #{invalid_keys}") if invalid_keys.present?

    # Validate required event field
    event = content_attrs['event']
    record.errors.add(:content_attributes, 'event is required for apple_time_picker') if event.blank?

    # Validate timeslots if present
    timeslots = content_attrs['timeslots'] || []
    if timeslots.present?
      timeslots.each_with_index do |slot, index|
        next unless slot.is_a?(Hash)

        # Identifier should now be auto-generated, but validate it exists
        record.errors.add(:content_attributes, "timeslot #{index} missing identifier") if slot['identifier'].blank?
        record.errors.add(:content_attributes, "timeslot #{index} missing startTime") if slot['startTime'].blank?
      end
    end

    # Validate style values for received and reply messages
    %w[received_style reply_style].each do |style_field|
      style_value = content_attrs[style_field]
      if style_value && !APPLE_STYLE_VALUES.include?(style_value)
        record.errors.add(:content_attributes, "#{style_field} has invalid value: #{style_value}. Must be one of: #{APPLE_STYLE_VALUES.join(', ')}")
      end
    end
  end

  def validate_apple_quick_reply!(record)
    content_attrs = record.content_attributes || {}

    # Validate top-level keys
    invalid_keys = content_attrs.keys.map(&:to_sym) - ALLOWED_APPLE_QUICK_REPLY_KEYS
    record.errors.add(:content_attributes, "contains invalid keys for apple_quick_reply: #{invalid_keys}") if invalid_keys.present?

    # Validate items
    items = content_attrs['items'] || []
    record.errors.add(:content_attributes, 'items is required for apple_quick_reply') if items.blank?
    record.errors.add(:content_attributes, 'apple_quick_reply must have between 2-5 items') if items.length < 2 || items.length > 5

    items.each_with_index do |item, index|
      next unless item.is_a?(Hash)

      invalid_item_keys = item.keys.map(&:to_sym) - ALLOWED_APPLE_QUICK_REPLY_ITEM_KEYS
      record.errors.add(:content_attributes, "quick_reply item #{index} contains invalid keys: #{invalid_item_keys}") if invalid_item_keys.present?

      record.errors.add(:content_attributes, "quick_reply item #{index} missing title") if item['title'].blank?
      # Identifier should now be auto-generated, but validate it exists
      record.errors.add(:content_attributes, "quick_reply item #{index} missing identifier") if item['identifier'].blank?
    end
  end

  def validate_apple_rich_link!(record)
    content_attrs = record.content_attributes || {}

    # Validate top-level keys
    invalid_keys = content_attrs.keys.map(&:to_sym) - ALLOWED_APPLE_RICH_LINK_KEYS
    record.errors.add(:content_attributes, "contains invalid keys for apple_rich_link: #{invalid_keys}") if invalid_keys.present?

    # URL is required
    url = content_attrs['url']
    record.errors.add(:content_attributes, 'url is required for apple_rich_link') if url.blank?

    # Validate URL format
    if url.present?
      begin
        uri = URI.parse(url)
        record.errors.add(:content_attributes, 'url must be a valid HTTP/HTTPS URL') unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
      rescue URI::InvalidURIError
        record.errors.add(:content_attributes, 'url must be a valid URL')
      end
    end

    # Title is required
    record.errors.add(:content_attributes, 'title is required for apple_rich_link') if content_attrs['title'].blank?

    # Validate image data if present
    if content_attrs['image_data'].present?
      record.errors.add(:content_attributes, 'image_mime_type is required when image_data is provided') if content_attrs['image_mime_type'].blank?

      # Validate MIME type
      mime_type = content_attrs['image_mime_type']
      unless ['image/jpeg', 'image/png', 'image/gif'].include?(mime_type)
        record.errors.add(:content_attributes, 'image_mime_type must be image/jpeg, image/png, or image/gif')
      end
    end

    # Validate video data if present
    return unless content_attrs['video_url'].present?

    record.errors.add(:content_attributes, 'video_mime_type is required when video_url is provided') if content_attrs['video_mime_type'].blank?

    # Validate video URL format
    begin
      video_uri = URI.parse(content_attrs['video_url'])
      unless video_uri.is_a?(URI::HTTP) || video_uri.is_a?(URI::HTTPS)
        record.errors.add(:content_attributes,
                          'video_url must be a valid HTTP/HTTPS URL')
      end
    rescue URI::InvalidURIError
      record.errors.add(:content_attributes, 'video_url must be a valid URL')
    end

    # Validate video MIME type
    video_mime_type = content_attrs['video_mime_type']
    return if ['video/mp4', 'video/mpeg', 'video/quicktime'].include?(video_mime_type)

    record.errors.add(:content_attributes, 'video_mime_type must be video/mp4, video/mpeg, or video/quicktime')
  end

  def validate_apple_pay!(record)
    content_attrs = record.content_attributes || {}

    # Validate top-level keys
    invalid_keys = content_attrs.keys.map(&:to_sym) - ALLOWED_APPLE_PAY_KEYS
    record.errors.add(:content_attributes, "contains invalid keys for apple_pay: #{invalid_keys}") if invalid_keys.present?

    # Payment request is required
    payment_request = content_attrs['payment_request']
    record.errors.add(:content_attributes, 'payment_request is required for apple_pay') if payment_request.blank?

    # Validate payment request structure
    return unless payment_request.present? && payment_request.is_a?(Hash)

    required_fields = %w[country_code currency_code supported_networks merchant_capabilities total]
    required_fields.each do |field|
      record.errors.add(:content_attributes, "payment_request missing required field: #{field}") if payment_request[field].blank?
    end
  end

  def validate_apple_authentication!(record)
    content_attrs = record.content_attributes || {}

    # Validate top-level keys
    invalid_keys = content_attrs.keys.map(&:to_sym) - ALLOWED_APPLE_AUTHENTICATION_KEYS
    record.errors.add(:content_attributes, "contains invalid keys for apple_authentication: #{invalid_keys}") if invalid_keys.present?

    # OAuth2 config is required
    oauth2 = content_attrs['oauth2']
    record.errors.add(:content_attributes, 'oauth2 is required for apple_authentication') if oauth2.blank?

    # Validate OAuth2 structure
    if oauth2.present? && oauth2.is_a?(Hash)
      required_fields = %w[provider client_id redirect_uri]
      required_fields.each do |field|
        record.errors.add(:content_attributes, "oauth2 missing required field: #{field}") if oauth2[field].blank?
      end
    end

    # Response encryption key is required
    return if content_attrs['response_encryption_key'].present?

    record.errors.add(:content_attributes,
                      'response_encryption_key is required for apple_authentication')
  end

  def validate_apple_form!(record)
    content_attrs = record.content_attributes || {}

    # Validate top-level keys
    invalid_keys = content_attrs.keys.map(&:to_sym) - ALLOWED_APPLE_FORM_KEYS
    record.errors.add(:content_attributes, "contains invalid keys for apple_form: #{invalid_keys}") if invalid_keys.present?

    # Check if using new pages-based format (Apple MSP Forms) or legacy flat format
    has_pages = content_attrs['pages'].present?
    has_fields = content_attrs['fields'].present?

    if has_pages
      # New pages-based format validation
      record.errors.add(:content_attributes, 'pages must be an array') unless content_attrs['pages'].is_a?(Array)
      record.errors.add(:content_attributes, 'title is required for apple_form') if content_attrs['title'].blank?
      # pages format doesn't require submit_url (handled by FormService)
    elsif has_fields
      # Legacy flat format validation
      record.errors.add(:content_attributes, 'fields must be an array') unless content_attrs['fields'].is_a?(Array)
      record.errors.add(:content_attributes, 'submit_url is required for apple_form') if content_attrs['submit_url'].blank?
    else
      # Neither format found
      record.errors.add(:content_attributes, 'either pages or fields is required for apple_form')
    end
  end

  def validate_apple_custom_app!(record)
    content_attrs = record.content_attributes || {}

    # Validate top-level keys
    invalid_keys = content_attrs.keys.map(&:to_sym) - ALLOWED_APPLE_CUSTOM_APP_KEYS
    record.errors.add(:content_attributes, "contains invalid keys for apple_custom_app: #{invalid_keys}") if invalid_keys.present?

    # App ID is required
    record.errors.add(:content_attributes, 'app_id is required for apple_custom_app') if content_attrs['app_id'].blank?

    # BID is required
    record.errors.add(:content_attributes, 'bid is required for apple_custom_app') if content_attrs['bid'].blank?

    # URL is required
    record.errors.add(:content_attributes, 'url is required for apple_custom_app') if content_attrs['url'].blank?
  end
end
