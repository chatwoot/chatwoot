class Api::V1::Accounts::AutomationRulesController < Api::V1::Accounts::BaseController
  before_action :check_authorization

  def index
    @automation_rules = Current.account.automation_rules.active
  end

  def create
    @automation_rule = Current.account.automation_rules.create(automation_rules_permit)
  end

  private

  def automation_rules_permit
    params.permit(
      :name, :description, :event_name, :account_id,
      conditions: [:attribute_key, :filter_operator, :query_operator, { values: [] }],
      actions: [:action_name, { action_params: [:intiated_at] }]
    )
  end
end
