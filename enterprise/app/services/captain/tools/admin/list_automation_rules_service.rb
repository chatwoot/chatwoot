class Captain::Tools::Admin::ListAutomationRulesService < Captain::Tools::Admin::BaseTool
  def self.name
    'list_automation_rules'
  end

  description 'List automation rules configured for the account'
  param :search, type: :string, desc: 'Optional filter by rule name (partial match)'
  param :active_only, type: :boolean, desc: 'When true, return only active rules'

  def execute(search: nil, active_only: false)
    rules = account.automation_rules
    rules = rules.active if ActiveModel::Type::Boolean.new.cast(active_only)
    rules = rules.where('name ILIKE ?', "%#{search}%") if search.present?

    return 'No automation rules found' if rules.none?

    rules.limit(100).map { |rule| format_automation_rule(rule) }.join("\n---\n")
  end
end
