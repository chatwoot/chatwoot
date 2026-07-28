class Api::V1::Accounts::Captain::ScenariosController < Api::V1::Accounts::Captain::BaseController
  before_action :ensure_captain_v2_enabled
  before_action -> { check_authorization(Captain::Scenario) }
  before_action :set_assistant
  before_action :set_scenario, only: [:show, :update, :destroy]

  def index
    @scenarios = assistant_scenarios.enabled
  end

  def show; end

  def create
    @scenario = assistant_scenarios.create!(scenario_params.merge(account: Current.account))
  end

  def update
    @scenario.update!(scenario_params)
  end

  def destroy
    @scenario.destroy
    head :no_content
  end

  private

  # Scenarios are a Captain v2-only feature; the shared base guard allows either flag, so require v2 here.
  def ensure_captain_v2_enabled
    return if current_account.feature_enabled?('captain_integration_v2')

    render json: { error: 'Captain is not enabled for this account' }, status: :forbidden
  end

  def set_assistant
    @assistant = account_assistants.find(params[:assistant_id])
  end

  def account_assistants
    @account_assistants ||= Current.account.captain_assistants
  end

  def set_scenario
    @scenario = assistant_scenarios.find(params[:id])
  end

  def assistant_scenarios
    @assistant.scenarios
  end

  def scenario_params
    params.require(:scenario).permit(:title, :description, :instruction, :enabled, tools: [])
  end
end
