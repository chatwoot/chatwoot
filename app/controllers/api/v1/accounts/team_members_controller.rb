class Api::V1::Accounts::TeamMembersController < Api::V1::Accounts::BaseController
  before_action :fetch_team
  before_action :check_authorization

  def index
    @team_members = @team.team_members.map(&:user)
  end

  def create
    ActiveRecord::Base.transaction do
      @team_members = params[:user_ids].map { |user_id| create_team_member(user_id) }
    end
  end

  def destroy
    ActiveRecord::Base.transaction do
      params[:user_ids].map { |user_id| remove_team_member(user_id) }
    end
    head :ok
  end

  private

  def create_team_member(user_id)
    @team.team_members.find_or_create_by(user_id: user_id)&.user
  end

  def remove_team_member(user_id)
    @team.team_members.find_by(user_id: user_id)&.destroy
  end

  def fetch_team
    @team = Current.account.teams.find(params[:team_id])
  end
end
