class Api::V1::Accounts::ChannelGroupsController < Api::V1::Accounts::BaseController
  before_action :fetch_channel_group, only: [:update, :destroy]
  before_action :check_authorization
  before_action :validate_channel_group_params, :validate_member_inboxes, only: [:create, :update]

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

  def validate_channel_group_params
    group = params.require(:channel_group)
    raise ActionController::ParameterMissing, :channel_group unless group.is_a?(ActionController::Parameters)
    raise ActionController::ParameterMissing, :name if group.key?(:name) && !group[:name].is_a?(String)
  end

  def validate_member_inboxes
    return unless params[:channel_group].key?(:inbox_ids)

    inbox_ids = params[:channel_group][:inbox_ids]
    raise ActionController::ParameterMissing, :inbox_ids unless inbox_ids.is_a?(Array) && inbox_ids.all? { |id| id.is_a?(Integer) && id.positive? }

    @member_inboxes = Current.account.inboxes.where(id: inbox_ids)
    raise ActionController::ParameterMissing, :inbox_ids unless @member_inboxes.size == inbox_ids.uniq.size
  end

  # An inbox belongs to at most one group, so assigning it here moves it out of
  # the group it was in.
  def save_with_members
    ActiveRecord::Base.transaction do
      @channel_group.save!
      @channel_group.inboxes = @member_inboxes if @member_inboxes
    end
  end
end
