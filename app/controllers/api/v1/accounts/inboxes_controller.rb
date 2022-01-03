class Api::V1::Accounts::InboxesController < Api::V1::Accounts::BaseController
  include Api::V1::InboxesHelper
  before_action :fetch_inbox, except: [:index, :create]
  before_action :fetch_agent_bot, only: [:set_agent_bot]
  # we are already handling the authorization in fetch inbox
  before_action :check_authorization, except: [:show]

  def index
    @inboxes = policy_scope(Current.account.inboxes.order_by_name.includes(:channel, { avatar_attachment: [:blob] }))
  end

  def show; end

  def assignable_agents
    @assignable_agents = (Current.account.users.where(id: @inbox.members.select(:user_id)) + Current.account.administrators).uniq
  end

  def campaigns
    @campaigns = @inbox.campaigns
  end

  def avatar
    @inbox.avatar.attachment.destroy! if @inbox.avatar.attached?
    head :ok
  end

  def create
    ActiveRecord::Base.transaction do
      channel = create_channel
      @inbox = Current.account.inboxes.build(
        {
          name: inbox_name(channel),
          channel: channel
        }.merge(
          permitted_params.except(:channel)
        )
      )
      @inbox.save!
    end
  end

  def update
    @inbox.update(permitted_params.except(:channel))
    @inbox.update_working_hours(params.permit(working_hours: Inbox::OFFISABLE_ATTRS)[:working_hours]) if params[:working_hours]
    channel_attributes = get_channel_attributes(@inbox.channel_type)

    # Inbox update doesn't necessarily need channel attributes
    return if permitted_params(channel_attributes)[:channel].blank?

    validate_email_channel(channel_attributes) if @inbox.inbox_type == 'Email'

    @inbox.channel.update!(permitted_params(channel_attributes)[:channel])
    update_channel_feature_flags
  end

  def agent_bot
    @agent_bot = @inbox.agent_bot
  end

  def set_agent_bot
    if @agent_bot
      agent_bot_inbox = @inbox.agent_bot_inbox || AgentBotInbox.new(inbox: @inbox)
      agent_bot_inbox.agent_bot = @agent_bot
      agent_bot_inbox.save!
    elsif @inbox.agent_bot_inbox.present?
      @inbox.agent_bot_inbox.destroy!
    end
    head :ok
  end

  def destroy
    @inbox.destroy
    head :ok
  end

  private

  def fetch_inbox
    @inbox = Current.account.inboxes.find(params[:id])
    authorize @inbox, :show?
  end

  def fetch_agent_bot
    @agent_bot = AgentBot.find(params[:agent_bot]) if params[:agent_bot]
  end

  def inbox_name(channel)
    return channel.try(:bot_name) if channel.is_a?(Channel::Telegram)

    permitted_params[:name]
  end

  def create_channel
    case permitted_params[:channel][:type]
    when 'web_widget'
      Current.account.web_widgets.create!(permitted_params(Channel::WebWidget::EDITABLE_ATTRS)[:channel].except(:type))
    when 'api'
      Current.account.api_channels.create!(permitted_params(Channel::Api::EDITABLE_ATTRS)[:channel].except(:type))
    when 'email'
      Current.account.email_channels.create!(permitted_params(Channel::Email::EDITABLE_ATTRS)[:channel].except(:type))
    when 'line'
      Current.account.line_channels.create!(permitted_params(Channel::Line::EDITABLE_ATTRS)[:channel].except(:type))
    when 'telegram'
      Current.account.telegram_channels.create!(permitted_params(Channel::Telegram::EDITABLE_ATTRS)[:channel].except(:type))
    when 'whatsapp'
      Current.account.whatsapp_channels.create!(permitted_params(Channel::Whatsapp::EDITABLE_ATTRS)[:channel].except(:type))
    end
  end

  def update_channel_feature_flags
    return unless @inbox.web_widget?
    return unless permitted_params(Channel::WebWidget::EDITABLE_ATTRS)[:channel].key? :selected_feature_flags

    @inbox.channel.selected_feature_flags = permitted_params(Channel::WebWidget::EDITABLE_ATTRS)[:channel][:selected_feature_flags]
    @inbox.channel.save!
  end

  def permitted_params(channel_attributes = [])
    params.permit(
      :name, :avatar, :greeting_enabled, :greeting_message, :enable_email_collect, :csat_survey_enabled,
      :enable_auto_assignment, :working_hours_enabled, :out_of_office_message, :timezone,
      channel: [:type, *channel_attributes]
    )
  end

  def get_channel_attributes(channel_type)
    if channel_type.constantize.const_defined?('EDITABLE_ATTRS')
      channel_type.constantize::EDITABLE_ATTRS.presence
    else
      []
    end
  end
end
