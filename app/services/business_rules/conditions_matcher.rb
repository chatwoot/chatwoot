# frozen_string_literal: true

# Duck-type wrapper so AutomationRules::ConditionsFilterService can evaluate
# embedded business-rule conditions without an AutomationRule AR row.
class BusinessRules::ConditionsMatcher
  RuleDuck = Struct.new(:id, :account, :conditions, keyword_init: true) do
    def authorization_error!
      # Embedded settings rules have no AR row / Reauthorizable counter.
    end
  end

  def self.match?(account:, conversation:, conditions:, rule_id: 'business_rule')
    list = Array(conditions).map { |c| c.is_a?(Hash) ? c.stringify_keys : c }.reject(&:blank?)
    return true if list.blank?

    # Guards do not support message / attribute_changed filters.
    list = list.reject do |condition|
      condition['filter_operator'].to_s == 'attribute_changed'
    end
    return true if list.blank?

    duck = RuleDuck.new(id: rule_id.to_s, account: account, conditions: list)
    AutomationRules::ConditionsFilterService.new(duck, conversation).perform
  end
end
