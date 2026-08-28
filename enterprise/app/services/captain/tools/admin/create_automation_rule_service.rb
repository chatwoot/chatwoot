class Captain::Tools::Admin::CreateAutomationRuleService < Captain::Tools::Admin::BaseTool
  def self.name
    'create_automation_rule'
  end

  description 'Create an automation rule. Requires user confirmation.'
  param :confirmed, type: :boolean, desc: 'Must be true after the user explicitly confirms the change', required: true
  param :name, type: :string, desc: 'Automation rule name', required: true
  param :event_name, type: :string, desc: 'Trigger event (e.g. conversation_created, conversation_updated, message_created)', required: true
  param :conditions_json, type: :string, desc: 'Conditions as a JSON array', required: true
  param :actions_json, type: :string, desc: 'Actions as a JSON array', required: true
  param :description, type: :string, desc: 'Automation rule description'
  param :active, type: :boolean, desc: 'Whether the rule is active'
  param :execution_delay, type: :integer, desc: 'Delay in minutes before actions run (requires delayed_automations feature)'

  def execute(confirmed:, name:, event_name:, conditions_json:, actions_json:, description: nil, active: true, execution_delay: nil)
    confirmation_error = require_confirmation!(confirmed, name: name, event_name: event_name, conditions_json: conditions_json,
                                                          actions_json: actions_json, description: description, active: active, execution_delay: execution_delay)
    return confirmation_error if confirmation_error.present?

    conditions = parse_json_array(conditions_json, 'conditions_json')
    return conditions if json_parse_error?(conditions)

    actions = parse_json_array(actions_json, 'actions_json')
    return actions if json_parse_error?(actions)

    return 'Delayed automations are not enabled for this account' if execution_delay.present? && !delayed_automations_enabled?

    rule = account.automation_rules.new(
      name: name,
      description: description,
      event_name: event_name,
      active: active.nil? || active,
      execution_delay: execution_delay,
      conditions: conditions,
      actions: actions
    )
    rule.save!

    "Automation rule created successfully.\n#{format_automation_rule(rule)}"
  rescue ActiveRecord::RecordInvalid => e
    "Failed to create automation rule: #{e.record.errors.full_messages.join(', ')}"
  end
end
