class Api::V1::Accounts::TeamMembersController < Api::V1::Accounts::BaseController
  before_action :fetch_team
  before_action :check_authorization

  def index
    @team_members = @team.team_members.map(&:user)
  end

  def create
    ActiveRecord::Base.transaction do
      @team_members = params[:user_ids].map { |user_id| @team.add_member(user_id) }
    end
  end

  def update
    ActiveRecord::Base.transaction do
      members_to_be_added_ids.each { |user_id| @team.add_member(user_id) }
      members_to_be_removed_ids.each { |user_id| @team.remove_member(user_id) }
    end
    @team_members = @team.members
    render action: 'create'
  end

  def destroy
    ActiveRecord::Base.transaction do
      params[:user_ids].map { |user_id| @team.remove_member(user_id) }
    end
    head :ok
  end

  private

  def members_to_be_added_ids
    params[:user_ids] - current_members_ids
  end

  def members_to_be_removed_ids
    current_members_ids - params[:user_ids]
  end

  def current_members_ids
    @current_members_ids ||= @team.members.pluck(:id)
  end

  def fetch_team
    @team = Current.account.teams.find(params[:team_id])
  end
end
