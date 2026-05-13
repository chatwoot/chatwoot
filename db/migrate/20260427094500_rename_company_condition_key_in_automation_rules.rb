class RenameCompanyConditionKeyInAutomationRules < ActiveRecord::Migration[7.1]
  def up
    migrate_automation_rule_conditions
    migrate_contact_custom_filter_queries
  end

  def down; end

  private

  def migrate_automation_rule_conditions
    AutomationRule.find_each do |rule|
      conditions = rename_company_attribute_key(rule.conditions)

      next if conditions == rule.conditions

      rule.update_column(:conditions, conditions) # rubocop:disable Rails/SkipsModelValidations
    end
  end

  def migrate_contact_custom_filter_queries
    CustomFilter.contact.find_each do |filter|
      query = filter.query.deep_dup
      payload = rename_company_attribute_key(query['payload'])
      next if payload == query['payload']

      query['payload'] = payload
      filter.update_column(:query, query) # rubocop:disable Rails/SkipsModelValidations
    end
  end

  def rename_company_attribute_key(conditions)
    return conditions unless conditions.is_a?(Array)

    conditions.map do |condition|
      next condition unless standard_company_condition?(condition)

      condition.merge('attribute_key' => 'company_name')
    end
  end

  def standard_company_condition?(condition)
    condition['attribute_key'] == 'company' &&
      condition['custom_attribute_type'].blank? &&
      condition['attribute_model'].in?([nil, '', 'standard'])
  end
end
