class ContentAttributeValidator < ActiveModel::Validator
  ALLOWED_SELECT_ITEM_KEYS = [:title, :value, :description].freeze
  ALLOWED_CARD_ITEM_KEYS = [:title, :description, :media_url, :actions].freeze
  ALLOWED_CARD_ITEM_ACTION_KEYS = [:text, :type, :payload, :uri].freeze
  ALLOWED_FORM_ITEM_KEYS = [:type, :placeholder, :label, :name, :options, :default, :required, :pattern, :title, :pattern_error].freeze
  ALLOWED_ARTICLE_KEYS = [:title, :description, :link].freeze
  REQUIRED_CTA_URL_KEYS = %w[display_text url].freeze
  OPTIONAL_CTA_URL_KEYS = %w[body header footer header_image].freeze
  CTA_URL_LINK_KEYS = %w[url header_image].freeze
  HTTP_URL_REGEX = URI::DEFAULT_PARSER.make_regexp(%w[http https])

  def validate(record)
    validate_cta_url!(record) if record.content_attributes.key?('whatsapp_cta_url')

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
  end

  private

  def validate_cta_url!(record)
    cta = record.content_attributes['whatsapp_cta_url']
    return record.errors.add(:content_attributes, 'whatsapp_cta_url should be a hash.') unless cta.is_a?(Hash)
    return record.errors.add(:content_attributes, 'whatsapp_cta_url is only supported on WhatsApp Cloud inboxes') unless cta_url_inbox?(record)
    return record.errors.add(:content_attributes, 'whatsapp_cta_url cannot be sent with attachments') if record.attachments.present?
    return record.errors.add(:content_attributes, 'whatsapp_cta_url requires message content') if record.content.blank?

    validate_cta_url_fields!(record, cta.with_indifferent_access)
  end

  def cta_url_inbox?(record)
    record.inbox&.channel.try(:provider) == 'whatsapp_cloud'
  end

  def validate_cta_url_fields!(record, cta)
    missing_keys = REQUIRED_CTA_URL_KEYS.reject { |key| present_string?(cta[key]) }
    record.errors.add(:content_attributes, "whatsapp_cta_url is missing #{missing_keys.join(', ')}") if missing_keys.present?

    invalid_keys = invalid_cta_url_keys(cta)
    record.errors.add(:content_attributes, "whatsapp_cta_url has invalid #{invalid_keys.join(', ')}") if invalid_keys.present?
  end

  def invalid_cta_url_keys(cta)
    OPTIONAL_CTA_URL_KEYS.select { |key| cta[key].present? && !cta[key].is_a?(String) } +
      CTA_URL_LINK_KEYS.select { |key| present_string?(cta[key]) && !cta[key].match?(HTTP_URL_REGEX) }
  end

  def present_string?(value)
    value.is_a?(String) && value.present?
  end

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
end
