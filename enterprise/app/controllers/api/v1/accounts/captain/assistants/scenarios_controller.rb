class Api::V1::Accounts::Captain::Assistants::ScenariosController < Api::V1::Accounts::BaseController
  before_action -> { check_authorization(Captain::Scenario) }
  before_action :set_assistant
  before_action :set_scenario, only: [:show, :update, :destroy]

  def index
    @scenarios = assistant_scenarios.enabled
  end

  def show; end

  def create
    @scenario = assistant_scenarios.create!(scenario_params)
  end

  def update
    @scenario.update!(scenario_params)
  end

  def destroy
    @scenario.destroy
    head :no_content
  end

  private

  def set_assistant
    @assistant = current_account.captain_assistants.find(params[:assistant_id])
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