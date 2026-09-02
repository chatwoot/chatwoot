class ContentAttributeValidator < ActiveModel::Validator
  ALLOWED_SELECT_ITEM_KEYS = [:title, :value].freeze
  ALLOWED_CARD_ITEM_KEYS = [:title, :description, :media_url, :actions].freeze
  ALLOWED_CARD_ITEM_ACTION_KEYS = [:text, :type, :payload, :uri].freeze
  ALLOWED_FORM_ITEM_KEYS = [:type, :placeholder, :label, :name, :options, :default, :required, :pattern, :title, :pattern_error].freeze
  ALLOWED_ARTICLE_KEYS = [:title, :description, :link].freeze

  def validate(record)
    case record.content_type
    when 'input_select'
      validate_dependent_items!(record, ALLOWED_SELECT_ITEM_KEYS)
    when 'cards'
      validate_dependent_items!(record, ALLOWED_CARD_ITEM_KEYS, validate_actions: true)
    when 'form'
      validate_dependent_items!(record, ALLOWED_FORM_ITEM_KEYS)
    when 'article'
      validate_dependent_items!(record, ALLOWED_ARTICLE_KEYS)
    end
  end

  private

  # `validate_item_attributes!` / `validate_item_actions!` assume `record.items` is an enumerable of
  # hashes and blow up with a NoMethodError on nil/malformed input instead of surfacing a normal
  # validation error, so only run them once `validate_items!` has confirmed that's safe.
  def validate_dependent_items!(record, valid_keys, validate_actions: false)
    return unless validate_items!(record)

    validate_item_attributes!(record, valid_keys)
    validate_item_actions!(record) if validate_actions
  end

  # Returns true when `record.items` is a present, well-formed array of hashes and it's safe for
  # the caller to run the per-item validations above.
  def validate_items!(record)
    if record.items.blank?
      record.errors.add(:content_attributes, 'At least one item is required.')
      return false
    end

    # `items` itself must be an Array before it's safe to call Array methods on it below -- a client
    # can send any JSON value here (e.g. a String or a Hash), and only an Array responds to `reject`.
    unless record.items.is_a?(Array) && record.items.reject { |item| item.is_a?(Hash) }.blank?
      record.errors.add(:content_attributes, 'Items should be a hash.')
      return false
    end

    true
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
