class Api::V1::Accounts::TeamsController < Api::V1::Accounts::BaseController
  before_action :fetch_team, except: [:index, :create]
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

  def update_leader
    old_leader = @team.team_members.find_by(leader: true)
    old_leader.update(leader: false) if old_leader.present?
    return if params[:user_id].blank?

    team_member = @team.team_members.find_by(user_id: params[:user_id])
    team_member.update(leader: true)
    fetch_team
  end

  private

  def fetch_team
    @team = Current.account.teams.find(params[:id])
  end

  def team_params
    params.require(:team).permit(:name, :description, :allow_auto_assign)
  end
end
