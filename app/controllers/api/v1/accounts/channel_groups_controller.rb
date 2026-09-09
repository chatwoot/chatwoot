class Api::V1::Accounts::ChannelGroupsController < Api::V1::Accounts::BaseController
  before_action :fetch_channel_group, only: [:update, :destroy]
  before_action :check_authorization

  def index
    @channel_groups = Current.account.channel_groups.includes(:inboxes).order(:name)
    @accessible_inbox_ids = policy_scope(Current.account.inboxes).pluck(:id)
  end

  def create
    @channel_group = Current.account.channel_groups.new(channel_group_params)
    save_with_members
  end

  def update
    @channel_group.assign_attributes(channel_group_params)
    save_with_members
  end

  def destroy
    @channel_group.destroy!
    head :ok
  end

  private

  def fetch_channel_group
    @channel_group = Current.account.channel_groups.find(params[:id])
  end

  def channel_group_params
    params.require(:channel_group).permit(:name)
  end

  # An inbox belongs to at most one group, so assigning it here moves it out of
  # the group it was in.
  def save_with_members
    ActiveRecord::Base.transaction do
      @channel_group.save!
      next if params[:channel_group][:inbox_ids].nil?

      @channel_group.inboxes = Current.account.inboxes.where(id: params[:channel_group][:inbox_ids])
    end
  end
end
