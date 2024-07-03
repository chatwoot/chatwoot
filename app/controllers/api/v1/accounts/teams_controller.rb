class Api::V1::Accounts::TeamsController < Api::V1::Accounts::BaseController
  before_action :fetch_team, only: [:show, :update, :destroy]
  before_action :check_authorization
  before_action :find_teams, only: [:index]

  def index; end

  def show; end

  def create
    @team = Current.account.teams.new(team_params)
    @team.save!
  end

  def update
    @team.update!(team_params)
  end

  def destroy
    labels = Current.account.labels.where(team_id: [@team.id])

    labels.each { |label| label.update!({ team_id: nil }) }

    @team.destroy!
    head :ok
  end

  private

  def fetch_team
    @team = Current.account.teams.find(params[:id])
  end

  def team_params
    params.require(:team).permit(:name, :description, :allow_auto_assign)
  end

  def find_teams
    @teams = @user.administrator? ? Current.account.teams : Current.user.teams
  end
end
