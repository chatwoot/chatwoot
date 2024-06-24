class Api::V1::Accounts::InboxTeamsController < Api::V1::Accounts::BaseController
  before_action :fetch_inbox
  before_action :current_teams_ids, only: [:create, :update]

  # get all teams based in inbox_id
  def show
    authorize @inbox, :show?
    fetch_updated_teams
  end

  # associate teams with inbox and return updated association
  def create
    authorize @inbox, :create?
    ActiveRecord::Base.transaction do
      teams_to_be_added_ids.map { |team_id| @inbox.add_team(team_id) }
    end
    fetch_updated_teams
  end

  # update association in teams with inbox and return updated association
  def update
    authorize @inbox, :update?
    update_teams_list
    fetch_updated_teams
  end

  def destroy
    authorize @inbox, :destroy?
    ActiveRecord::Base.transaction do
      params[:team_ids].map { |team_id| @inbox.remove_team(team_id) }
    end
    head :ok
  end

  private

  # get all teams informations associated with inbox
  def fetch_updated_teams
    @teams = Current.account.teams.where(id: @inbox.teams.select(:team_id))
  end

  def update_teams_list
    ActiveRecord::Base.transaction do
      teams_to_be_added_ids.each { |team_id| @inbox.add_team(team_id) }
      teams_to_be_removed_ids.each { |team_id| @inbox.remove_team(team_id) }
    end
  end

  # make the difference between request ids and current teams ids
  def teams_to_be_added_ids
    params[:team_ids] - @current_teams_ids
  end

  # make the difference between current_teams_ids and current request ids
  def teams_to_be_removed_ids
    @current_teams_ids - params[:team_ids]
  end

  # get all teams ids associated with inbox
  def current_teams_ids
    @current_teams_ids = @inbox.teams.pluck(:id)
  end

  # get current inbox based on id params of request
  def fetch_inbox
    @inbox = Current.account.inboxes.find(params[:inbox_id])
  end
end
