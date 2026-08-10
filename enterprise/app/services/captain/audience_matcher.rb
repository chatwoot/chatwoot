# Evaluates an assistant's audience condition tree in-memory against the conversation's contact.
# A node is either a group ({ operator:, conditions: [...] }) or a leaf
# ({ attribute_key:, filter_operator:, values: [...] }). Operator semantics mirror
# Contacts::FilterService so audiences match the same contacts as segments.
class Captain::AudienceMatcher
  CONTACT_STANDARD = %w[name email phone_number identifier blocked created_at last_activity_at].freeze
  CONTACT_ADDITIONAL = %w[country_code city company_name].freeze
  CONVERSATION_ADDITIONAL = %w[browser_language].freeze
  OPERATORS = %w[equal_to not_equal_to contains does_not_contain is_present is_not_present starts_with
                 is_greater_than is_less_than days_before].freeze
  # Root group -> sub-group -> leaves.
  MAX_DEPTH = 3

  def initialize(audience)
    @root = audience
  end

  def matches?(contact, conversation)
    return true if @root.blank?

    @contact = contact
    @conversation = conversation
    matches_node?(@root)
  end

  private

  def matches_node?(node)
    node = node.with_indifferent_access
    node.key?(:conditions) ? matches_group?(node) : matches_leaf?(node)
  end

  def matches_group?(group)
    conditions = Array(group[:conditions])
    if group[:operator].to_s.casecmp?('or')
      conditions.any? { |child| matches_node?(child) }
    else
      conditions.all? { |child| matches_node?(child) }
    end
  end

  def matches_leaf?(leaf)
    key = leaf[:attribute_key]
    actual = attribute_value(key)
    values = Array(leaf[:values])

    case leaf[:filter_operator]
    when 'is_present'     then actual.present?
    when 'is_not_present' then actual.blank?
    when 'equal_to'       then values.any? { |expected| value_equal?(key, actual, expected) }
    when 'not_equal_to'   then negative_equality_match?(key, actual, values)
    else matches_text_or_range?(leaf[:filter_operator], actual, values.first)
    end
  end

  def attribute_value(key)
    case key
    when *CONTACT_STANDARD        then @contact[key]
    when *CONTACT_ADDITIONAL      then @contact.additional_attributes[key]
    when 'labels'                 then @contact.label_list
    when *CONVERSATION_ADDITIONAL then @conversation.additional_attributes[key]
    when 'hmac_verified'          then hmac_verified?
    else @contact.custom_attributes[key]
    end
  end

  def hmac_verified?
    @conversation.contact_inbox&.hmac_verified || false
  end

  # labels is a has-tag check, booleans cast the expected string, phone numbers
  # ignore the "+" prefix, and text compares case-insensitively.
  def value_equal?(key, actual, expected)
    return Array(actual).include?(expected) if key == 'labels'
    return ActiveModel::Type::Boolean.new.cast(expected) == (actual == true) if boolean_condition?(key, actual, expected)
    return numeric_equal?(actual, expected) if actual.is_a?(Numeric) || numeric_attribute?(key)

    normalize(key, actual) == normalize(key, expected)
  end

  def numeric_equal?(actual, expected)
    BigDecimal(actual.to_s) == BigDecimal(expected.to_s)
  rescue ArgumentError, TypeError
    false
  end

  def negative_equality_match?(key, actual, values)
    if actual.nil?
      custom_attribute = custom_attribute?(key)
      return custom_attribute unless custom_attribute && checkbox_attribute?(key)
    end

    values.none? { |expected| value_equal?(key, actual, expected) }
  end

  def custom_attribute?(key)
    CONTACT_STANDARD.exclude?(key) && CONTACT_ADDITIONAL.exclude?(key) && CONVERSATION_ADDITIONAL.exclude?(key) &&
      %w[labels hmac_verified].exclude?(key)
  end

  # An unset checkbox attribute counts as false.
  def boolean_condition?(key, actual, expected)
    [true, false].include?(actual) ||
      (actual.nil? && %w[true false].include?(expected.to_s) && checkbox_attribute?(key))
  end

  def checkbox_attribute?(key)
    custom_attribute_types[key] == 'checkbox'
  end

  def numeric_attribute?(key)
    %w[number currency percent].include?(custom_attribute_types[key])
  end

  def custom_attribute_types
    @custom_attribute_types ||= @contact.account.custom_attribute_definitions.contact_attribute.each_with_object({}) do |definition, types|
      types[definition.attribute_key] = definition.attribute_display_type
    end
  end

  def normalize(key, value)
    return value if value.nil?
    return "+#{value.to_s.delete('+')}" if key == 'phone_number'

    value.is_a?(String) ? value.downcase : value
  end

  def matches_text_or_range?(operator, actual, expected)
    case operator
    when 'contains'         then actual.to_s.downcase.include?(expected.to_s.downcase)
    when 'does_not_contain' then excludes_text?(actual, expected)
    when 'starts_with'      then actual.to_s.downcase.start_with?(expected.to_s.downcase)
    when 'is_greater_than'  then compare(actual, expected) == 1
    when 'is_less_than'     then compare(actual, expected) == -1
    when 'days_before'      then older_than_days?(actual, expected)
    else false
    end
  end

  def excludes_text?(actual, expected)
    !actual.nil? && actual.to_s.downcase.exclude?(expected.to_s.downcase)
  end

  # -1/0/1 like <=>, or nil when blank or unparseable (never matches).
  def compare(actual, expected)
    return nil if actual.blank?

    actual = Time.zone.parse(actual) if iso_date_string?(actual)

    if actual.is_a?(Date) || actual.acts_like?(:time)
      expected_date = to_date(expected)
      actual.to_date <=> expected_date if expected_date
    else
      BigDecimal(actual.to_s) <=> BigDecimal(expected.to_s)
    end
  rescue ArgumentError, TypeError
    nil
  end

  # Custom date attributes store ISO strings in jsonb; treat them as dates the way
  # Contacts::FilterService does (it casts them in SQL).
  def iso_date_string?(value)
    value.is_a?(String) && Date.iso8601(value).present?
  rescue ArgumentError
    false
  end

  def older_than_days?(actual, days)
    date = to_date(actual)
    date.present? && date < Time.zone.today - days.to_i.days
  end

  def to_date(value)
    return value.to_date if value.respond_to?(:to_date)

    Date.parse(value.to_s)
  rescue ArgumentError, TypeError
    nil
  end
end
