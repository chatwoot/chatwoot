class Api::V1::Accounts::AutomationRulesController < Api::V1::Accounts::BaseController
  def index; end

  def create
    AutomationRule.new(automation_rules_permit.merge(account_id: Current.account.id)).save!
    head :ok
  end

  private

  def automation_rules_permit
    params.permit(
      :name, :description, :event_name,
      conditions: [:attribute, :filter_operator, :value, :query_operator],
      actions: [assign_best_agents: [], send_message: [:message], assign_to_team: [], add_label: [], update_additional_attributes: [:intiated_at]]
    )
  end
end
