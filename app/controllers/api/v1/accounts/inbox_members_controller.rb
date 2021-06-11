class Api::V1::Accounts::InboxMembersController < Api::V1::Accounts::BaseController
  before_action :fetch_inbox, only: [:create, :show]
  before_action :current_agents_ids, only: [:create]

  def create
    authorize @inbox, :create?
    begin
      # update also done via same action
      update_agents_list
      head :ok
    rescue StandardError => e
      Rails.logger.debug "Rescued: #{e.inspect}"
      render_could_not_create_error('Could not add agents to inbox')
    end
  end

  def show
    authorize @inbox, :show?
    @agents = Current.account.users.where(id: @inbox.members.select(:user_id))
  end

  private

  def update_agents_list
    # get all the user_ids which the inbox currently has as members.
    # get the list of  user_ids from params
    # the missing ones are the agents which are to be deleted from the inbox
    # the new ones are the agents which are to be added to the inbox
    ActiveRecord::Base.transaction do
      agents_to_be_added_ids.each { |user_id| @inbox.add_member(user_id) }
      agents_to_be_removed_ids.each { |user_id| @inbox.remove_member(user_id) }
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
