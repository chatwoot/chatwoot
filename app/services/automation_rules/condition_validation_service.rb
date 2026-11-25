class AutomationRules::ConditionValidationService
  ATTRIBUTE_MODEL = 'conversation_attribute'.freeze

  def initialize(rule)
    @rule = rule
    @account = rule.account

    file = File.read('./lib/filters/filter_keys.yml')
    @filters = YAML.safe_load(file)

    @conversation_filters = @filters['conversations']
    @contact_filters = @filters['contacts']
    @message_filters = @filters['messages']
  end

  def perform
    @rule.conditions.each do |condition|
      return false unless valid_condition?(condition) && valid_query_operator?(condition)
    end

    true
  end

  private

  def valid_query_operator?(condition)
    query_operator = condition['query_operator']

    return true if query_operator.nil?
    return true if query_operator.empty?

    %w[AND OR].include?(query_operator.upcase)
  end

  def valid_condition?(condition)
    key = condition['attribute_key']
    attribute_model = condition['custom_attribute_type']
    # Same precedence as ConditionsFilterService#apply_filter: a condition that declares a
    # custom_attribute_type is about an account attribute, so it must not be validated against a
    # standard key that happens to share the name -- its operators are a different set.
    return custom_attribute_present?(key, attribute_model) if attribute_model.present?

    if key == Captain::AutomationConditionService::ATTRIBUTE_KEY
      return Captain::AutomationConditionService::OPERATORS.include?(condition['filter_operator'])
    end

    standard_filter = @conversation_filters[key] || @contact_filters[key] || @message_filters[key]
    return operation_valid?(condition, standard_filter) if standard_filter

    custom_attribute_present?(key, attribute_model)
  end

  def operation_valid?(condition, filter)
    filter_operator = condition['filter_operator']

    # attribute changed is a special case
    return true if filter_operator == 'attribute_changed'

    filter['filter_operators'].include?(filter_operator)
  end

  def custom_attribute_present?(attribute_key, attribute_model)
    attribute_model = attribute_model.presence || self.class::ATTRIBUTE_MODEL

    @account.custom_attribute_definitions.where(
      attribute_model: attribute_model
    ).find_by(attribute_key: attribute_key).present?
  end
end
