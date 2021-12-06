class Api::V1::Accounts::AutomationRulesController < Api::V1::Accounts::BaseController
  def index; end

  def create
    Current.account.automation_rules.create(automation_rules_permit)
    head :ok
  end

  private

  def automation_rules_permit
    params.permit(
      :name, :description, :event_name, :account_id,
      conditions: [:attribute_key, :filter_operator, :query_operator, values: []],
      actions: [:action_name, action_params: [:intiated_at]]
    )
  end
end
