class Captain::Tools::Admin::DeleteAutomationRuleService < Captain::Tools::Admin::BaseTool
  def self.name
    'delete_automation_rule'
  end

  description 'Delete an automation rule. Requires user confirmation.'
  param :confirmed, type: :boolean, desc: 'Must be true after the user explicitly confirms the change', required: true
  param :automation_rule_id, type: :integer, desc: 'ID of the automation rule to delete', required: true

  def execute(confirmed:, automation_rule_id:)
    confirmation_error = require_confirmation!(confirmed, automation_rule_id: automation_rule_id)
    return confirmation_error if confirmation_error.present?

    rule = account.automation_rules.find_by(id: automation_rule_id)
    return 'Automation rule not found' if rule.blank?

    rule_name = rule.name
    rule.destroy!

    "Automation rule '#{rule_name}' deleted successfully."
  end
end
