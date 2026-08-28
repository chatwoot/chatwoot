class Captain::Tools::Admin::GetAutomationRuleService < Captain::Tools::Admin::BaseTool
  def self.name
    'get_automation_rule'
  end

  description 'Get detailed settings for a specific automation rule'
  param :automation_rule_id, type: :integer, desc: 'ID of the automation rule to retrieve', required: true

  def execute(automation_rule_id:)
    rule = account.automation_rules.find_by(id: automation_rule_id)
    return 'Automation rule not found' if rule.blank?

    format_automation_rule(rule)
  end
end
