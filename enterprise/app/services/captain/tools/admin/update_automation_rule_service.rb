class Captain::Tools::Admin::UpdateAutomationRuleService < Captain::Tools::Admin::BaseTool
  def self.name
    'update_automation_rule'
  end

  description 'Update an automation rule. Requires user confirmation.'
  param :confirmed, type: :boolean, desc: 'Must be true after the user explicitly confirms the change', required: true
  param :automation_rule_id, type: :integer, desc: 'ID of the automation rule to update', required: true
  param :name, type: :string, desc: 'Automation rule name'
  param :description, type: :string, desc: 'Automation rule description'
  param :event_name, type: :string, desc: 'Trigger event'
  param :active, type: :boolean, desc: 'Whether the rule is active'
  param :execution_delay, type: :integer, desc: 'Delay in minutes before actions run'
  param :conditions_json, type: :string, desc: 'Conditions as a JSON array'
  param :actions_json, type: :string, desc: 'Actions as a JSON array'

  def execute(confirmed:, automation_rule_id:, conditions_json: nil, actions_json: nil, **attributes)
    confirmation_error = require_confirmation!(confirmed, automation_rule_id: automation_rule_id, conditions_json: conditions_json,
                                                          actions_json: actions_json, **attributes)
    return confirmation_error if confirmation_error.present?

    rule = account.automation_rules.find_by(id: automation_rule_id)
    return 'Automation rule not found' if rule.blank?

    return 'Delayed automations are not enabled for this account' if attributes.key?(:execution_delay) &&
                                                                     !attributes[:execution_delay].nil? &&
                                                                     !delayed_automations_enabled?

    conditions = parse_json_array(conditions_json, 'conditions_json')
    return conditions if json_parse_error?(conditions)

    actions = parse_json_array(actions_json, 'actions_json')
    return actions if json_parse_error?(actions)

    updates = rule_updates(attributes)
    rule.conditions = conditions if conditions.present?
    rule.actions = actions if actions.present?
    return 'No changes were provided' if updates.blank? && conditions.blank? && actions.blank?

    rule.assign_attributes(updates)
    rule.save!

    "Automation rule updated successfully.\n#{format_automation_rule(rule)}"
  rescue ActiveRecord::RecordInvalid => e
    "Failed to update automation rule: #{e.record.errors.full_messages.join(', ')}"
  end

  private

  def rule_updates(attributes)
    {}.tap do |updates|
      updates[:name] = attributes[:name] unless attributes[:name].nil?
      updates[:description] = attributes[:description] unless attributes[:description].nil?
      updates[:event_name] = attributes[:event_name] unless attributes[:event_name].nil?
      updates[:active] = attributes[:active] unless attributes[:active].nil?
      updates[:execution_delay] = attributes[:execution_delay] unless attributes[:execution_delay].nil?
    end
  end
end
