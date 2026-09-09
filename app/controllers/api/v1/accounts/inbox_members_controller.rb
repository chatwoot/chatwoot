class Api::V1::Accounts::InboxMembersController < Api::V1::Accounts::BaseController
  before_action :fetch_inbox
  before_action :current_agents_ids, only: [:create, :update]

  def show
    authorize @inbox, :show?
    fetch_updated_agents
  end

  def create
    authorize @inbox, :create?
    added_ids = agents_to_be_added_ids
    ActiveRecord::Base.transaction do
      @inbox.add_members(added_ids)
    end
    fetch_updated_agents
    broadcast_agents_updated(added_ids)
  end

  def update
    authorize @inbox, :update?
    added_ids = agents_to_be_added_ids
    removed_ids = agents_to_be_removed_ids
    update_agents_list(added_ids, removed_ids)
    fetch_updated_agents
    broadcast_agents_updated(added_ids + removed_ids)
  end

  def destroy
    authorize @inbox, :destroy?
    user_ids = params[:user_ids]
    ActiveRecord::Base.transaction do
      @inbox.remove_members(user_ids)
    end
    broadcast_agents_updated(user_ids)
    head :ok
  end

  private

  def broadcast_agents_updated(user_ids)
    return if user_ids.blank?

    users = Current.account.users.where(id: user_ids)
    users.each do |user|
      Rails.configuration.dispatcher.dispatch(
        Events::Types::AGENT_UPDATED,
        Time.zone.now,
        user: user,
        account_id: Current.account.id
      )
    end
  end

  def fetch_updated_agents
    @agents = Current.account.users.where(id: @inbox.members.select(:user_id))
  end

  def update_agents_list(added_ids, removed_ids)
    ActiveRecord::Base.transaction do
      @inbox.add_members(added_ids)
      @inbox.remove_members(removed_ids)
    end
  end

  def agents_to_be_added_ids
    params[:user_ids] - @current_agents_ids
  end

  def agents_to_be_removed_ids
    @current_agents_ids - params[:user_ids]
  end

  def current_agents_ids
    @current_agents_ids = @inbox.members.pluck(:id)
  end

  def fetch_inbox
    @inbox = Current.account.inboxes.find(params[:inbox_id])
  end
end
