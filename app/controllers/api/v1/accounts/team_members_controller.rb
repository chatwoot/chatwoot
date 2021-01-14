class Api::V1::Accounts::TeamMembersController < Api::V1::Accounts::BaseController
  before_action :fetch_team
  before_action :check_authorization

  def index
    render json: @team.team_members.map(&:user)
  end

  def create
    @team.team_members.find_or_create_by(user_id: params[:user_id])
    head :ok
  end

  def destroy
    @team.team_members.find_by(user_id: params[:user_id])&.destroy
    head :ok
  end

  private

  def fetch_team
    @team = Current.account.teams.find(params[:team_id])
  end
end
