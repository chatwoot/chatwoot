# Builds the filter field descriptions Captain::FilterRecommendationService asks Jev about.
module Captain::FilterFieldBuilder
  MAX_FIELDS = 40
  MAX_OPTIONS = 60
  EQUALITY_OPERATORS = %w[equal_to not_equal_to].freeze
  PRESENCE_OPERATORS = %w[equal_to not_equal_to is_present is_not_present].freeze
  # Contains comes first, because a typed fragment such as a domain is more often part of a value than all of it.
  CONTAINMENT_OPERATORS = %w[contains does_not_contain equal_to not_equal_to].freeze
  TRAITS = { multiple: false, ordered: false, date: false, text: false, action: false }.freeze

  private

  def options(relation, value_column, label_column)
    relation.order(:id).limit(MAX_OPTIONS).pluck(value_column, label_column)
  end

  # Date fields have no operators or options. Jev picks a date preset for them instead.
  def date_field(key, label)
    field(key, label, [], [], date: true)
  end

  # Text fields have no options. Jev points at the words of the description that hold the value instead.
  def text_field(key, label, operators)
    field(key, label, operators, [], text: true)
  end

  def list_attribute_fields(attribute_model)
    account.custom_attribute_definitions.where(attribute_model: attribute_model).list.order(:id).map do |definition|
      values = definition.attribute_values.first(MAX_OPTIONS).map { |value| [value, value] }
      field(definition.attribute_key, definition.attribute_display_name, EQUALITY_OPERATORS, values)
    end
  end

  # `multiple` marks fields whose filter accepts several values at once.
  # `ordered` marks fields whose options run from lowest to highest, such as priority.
  # `date` marks timestamp fields, which Jev answers with a date preset.
  # `text` marks free-text fields, whose value Jev points at in the description.
  # `action` marks automation actions, which the service returns in the action shape.
  def field(key, label, operators, values, **traits)
    {
      key: key, label: label, operators: operators,
      options: values.map { |value, name| { value: value, label: name.to_s } }
    }.merge(TRAITS, traits.slice(*TRAITS.keys))
  end
end
