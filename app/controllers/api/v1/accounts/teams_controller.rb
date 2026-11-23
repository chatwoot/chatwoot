class Api::V1::Accounts::TeamsController < Api::V1::Accounts::BaseController
  before_action :fetch_team, only: [:show, :update, :destroy]
  before_action :check_authorization

  def index
    @teams = Current.account.teams
  end

  def show; end

  def create
    @team = Current.account.teams.new(team_params)
    @team.save!
  end

  def update
    @team.update!(team_params)
  end

  def destroy
    @team.destroy!
    head :ok
  end

  private

  def fetch_team
    @team = Current.account.teams.find(params[:id])
  end

  def team_params
    widen_calls = params.dig(:team, :widen_calls)
    raise ActionController::ParameterMissing, :widen_calls unless widen_calls.nil? || Team.widen_calls.key?(widen_calls)

    params.require(:team).permit(:name, :description, :allow_auto_assign, :icon, :icon_color, :widen_calls)
  end
end
