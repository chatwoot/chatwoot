class ContentAttributeValidator < ActiveModel::Validator
  ALLOWED_SELECT_ITEM_KEYS = [:title, :value, :description].freeze
  ALLOWED_CARD_ITEM_KEYS = [:title, :description, :media_url, :actions].freeze
  ALLOWED_CARD_ITEM_ACTION_KEYS = [:text, :type, :payload, :uri].freeze
  ALLOWED_FORM_ITEM_KEYS = [:type, :placeholder, :label, :name, :options, :default, :required, :pattern, :title, :pattern_error].freeze
  ALLOWED_ARTICLE_KEYS = [:title, :description, :link].freeze
  ALLOWED_WHATSAPP_CTA_URL_KEYS = [:display_text, :url, :body, :header, :header_image, :footer].freeze
  WHATSAPP_CTA_DISPLAY_TEXT_MAX_LENGTH = 20
  WHATSAPP_CTA_BODY_MAX_LENGTH = 1024
  WHATSAPP_CTA_HEADER_FOOTER_MAX_LENGTH = 60

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
    end

    validate_whatsapp_cta_url!(record)
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

  def validate_whatsapp_cta_url!(record)
    return if record.content_attributes.blank?

    cta_params = record.content_attributes['whatsapp_cta_url'] || record.content_attributes[:whatsapp_cta_url]
    return if cta_params.nil?
    return unless valid_whatsapp_cta_context?(record)

    unless cta_params.is_a?(Hash)
      record.errors.add(:content_attributes, 'whatsapp_cta_url should be a hash.')
      return
    end

    validate_whatsapp_cta_url_attributes!(record, cta_params.with_indifferent_access)
  end

  def valid_whatsapp_cta_context?(record)
    unless whatsapp_cloud_inbox?(record)
      record.errors.add(:content_attributes, 'whatsapp_cta_url is only supported for WhatsApp Cloud inboxes')
      return false
    end

    return true unless competing_whatsapp_message_type?(record)

    record.errors.add(:content_attributes, 'whatsapp_cta_url is only supported on outgoing non-private text messages')
    false
  end

  def whatsapp_cloud_inbox?(record)
    channel = (record.inbox || record.conversation&.inbox)&.channel
    channel.is_a?(Channel::Whatsapp) && channel.provider == 'whatsapp_cloud'
  end

  def competing_whatsapp_message_type?(record)
    !record.outgoing? || record.private? || (record.content_type.present? && record.content_type != 'text') ||
      record.attachments.present? || competing_whatsapp_attributes?(record)
  end

  def competing_whatsapp_attributes?(record)
    additional = record.additional_attributes.is_a?(Hash) ? record.additional_attributes : {}
    has_template = additional['template_params'].present? || additional[:template_params].present?
    contact_info = record.content_attributes['whatsapp_contact_info'] || record.content_attributes[:whatsapp_contact_info]
    has_template || (contact_info.is_a?(Hash) && (contact_info['type'] || contact_info[:type]) == 'request')
  end

  def validate_whatsapp_cta_url_attributes!(record, cta_params)
    invalid_keys = cta_params.keys.map(&:to_sym) - ALLOWED_WHATSAPP_CTA_URL_KEYS
    record.errors.add(:content_attributes, "contains invalid keys for whatsapp_cta_url : #{invalid_keys}") if invalid_keys.present?
    validate_cta_required_fields!(record, cta_params)
    validate_cta_optional_fields!(record, cta_params)
    validate_cta_field_lengths!(record, cta_params)
  end

  def validate_cta_required_fields!(record, cta_params)
    record.errors.add(:content_attributes, 'display_text is required for whatsapp_cta_url') if invalid_cta_param?(cta_params[:display_text])
    validate_cta_url_field!(record, cta_params[:url])
    validate_cta_body_field!(record, cta_params)
  end

  def validate_cta_url_field!(record, url)
    if invalid_cta_param?(url)
      record.errors.add(:content_attributes, 'url is required for whatsapp_cta_url')
    elsif !valid_http_url?(url)
      record.errors.add(:content_attributes, 'url must be a valid HTTP(S) URL for whatsapp_cta_url')
    end
  end

  def validate_cta_body_field!(record, cta_params)
    if !cta_params[:body].nil? && !cta_params[:body].is_a?(String)
      record.errors.add(:content_attributes, 'body must be a string for whatsapp_cta_url')
    elsif cta_params[:body].blank? && record.content.blank?
      record.errors.add(:content_attributes, 'body or message content is required for whatsapp_cta_url')
    end
  end

  def validate_cta_optional_fields!(record, cta_params)
    [:header, :footer].each do |key|
      next if cta_params[key].nil?

      record.errors.add(:content_attributes, "#{key} must be a string for whatsapp_cta_url") unless cta_params[key].is_a?(String)
    end
    validate_cta_header_image!(record, cta_params)
  end

  def validate_cta_header_image!(record, cta_params)
    if !cta_params[:header_image].nil? && (!cta_params[:header_image].is_a?(String) || !valid_http_url?(cta_params[:header_image]))
      record.errors.add(:content_attributes, 'header_image must be a valid HTTP(S) URL for whatsapp_cta_url')
    end
    return if cta_params[:header].blank? || cta_params[:header_image].blank?

    record.errors.add(:content_attributes, 'cannot specify both header and header_image for whatsapp_cta_url')
  end

  def validate_cta_field_lengths!(record, cta_params)
    validate_cta_max_length!(record, :display_text, cta_params[:display_text], WHATSAPP_CTA_DISPLAY_TEXT_MAX_LENGTH)
    validate_cta_max_length!(record, :body, cta_params[:body].presence || record.content, WHATSAPP_CTA_BODY_MAX_LENGTH)
    validate_cta_max_length!(record, :header, cta_params[:header], WHATSAPP_CTA_HEADER_FOOTER_MAX_LENGTH)
    validate_cta_max_length!(record, :footer, cta_params[:footer], WHATSAPP_CTA_HEADER_FOOTER_MAX_LENGTH)
  end

  def validate_cta_max_length!(record, field, value, max_length)
    return unless value.is_a?(String) && value.length > max_length

    record.errors.add(:content_attributes, "#{field} must be at most #{max_length} characters for whatsapp_cta_url")
  end

  def invalid_cta_param?(value)
    value.blank? || !value.is_a?(String)
  end

  def valid_http_url?(value)
    uri = URI.parse(value)
    uri.is_a?(URI::HTTP) && uri.host.present?
  rescue URI::InvalidURIError
    false
  end
end
