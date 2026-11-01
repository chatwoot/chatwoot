class ContentAttributeValidator < ActiveModel::Validator
  ALLOWED_SELECT_ITEM_KEYS = [:title, :value, :description].freeze
  ALLOWED_CARD_ITEM_KEYS = [:title, :description, :media_url, :actions].freeze
  ALLOWED_CARD_ITEM_ACTION_KEYS = [:text, :type, :payload, :uri].freeze
  ALLOWED_FORM_ITEM_KEYS = [:type, :placeholder, :label, :name, :options, :default, :required, :pattern, :title, :pattern_error].freeze
  ALLOWED_ARTICLE_KEYS = [:title, :description, :link].freeze
  ALLOWED_WHATSAPP_CTA_URL_KEYS = [:display_text, :url, :body, :header, :header_image, :footer].freeze

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

    unless cta_params.is_a?(Hash)
      record.errors.add(:content_attributes, 'whatsapp_cta_url should be a hash.')
      return
    end

    validate_whatsapp_cta_url_attributes!(record, cta_params.with_indifferent_access)
  end

  def validate_whatsapp_cta_url_attributes!(record, cta_params)
    invalid_keys = cta_params.keys.map(&:to_sym) - ALLOWED_WHATSAPP_CTA_URL_KEYS
    record.errors.add(:content_attributes, "contains invalid keys for whatsapp_cta_url : #{invalid_keys}") if invalid_keys.present?
    record.errors.add(:content_attributes, 'display_text is required for whatsapp_cta_url') if invalid_cta_param?(cta_params[:display_text])
    record.errors.add(:content_attributes, 'url is required for whatsapp_cta_url') if invalid_cta_param?(cta_params[:url])
    record.errors.add(:content_attributes, 'body or message content is required for whatsapp_cta_url') if cta_params[:body].blank? && record.content.blank?
  end

  def invalid_cta_param?(value)
    value.blank? || !value.is_a?(String)
  end
end
