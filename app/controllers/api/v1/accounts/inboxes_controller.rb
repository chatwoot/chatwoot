class Api::V1::Accounts::InboxesController < Api::V1::Accounts::BaseController
  before_action :fetch_inbox, except: [:index, :create]
  before_action :fetch_agent_bot, only: [:set_agent_bot]
  before_action :check_authorization

  def index
    @inboxes = policy_scope(Current.account.inboxes.order_by_name.includes(:channel, :avatar_attachment))
  end

  def create
    ActiveRecord::Base.transaction do
      channel = create_channel
      @inbox = Current.account.inboxes.build(
        name: permitted_params[:name],
        greeting_message: permitted_params[:greeting_message],
        greeting_enabled: permitted_params[:greeting_enabled],
        channel: channel
      )
      @inbox.avatar.attach(permitted_params[:avatar])
      @inbox.save!
    end
  end

  def update
    @inbox.update(inbox_update_params.except(:channel))
    return unless @inbox.channel.is_a?(Channel::WebWidget) && inbox_update_params[:channel].present?

    @inbox.channel.update!(inbox_update_params[:channel])
    update_channel_feature_flags
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
  end

  def fetch_agent_bot
    @agent_bot = AgentBot.find(params[:agent_bot]) if params[:agent_bot]
  end

  def check_authorization
    authorize(Inbox)
  end

  def create_channel
    case permitted_params[:channel][:type]
    when 'web_widget'
      Current.account.web_widgets.create!(permitted_params[:channel].except(:type))
    when 'api'
      Current.account.api_channels.create!(permitted_params[:channel].except(:type))
    when 'email'
      Current.account.email_channels.create!(permitted_params[:channel].except(:type))
    end
  end

  def update_channel_feature_flags
    return unless inbox_update_params[:channel].key? :selected_feature_flags

    @inbox.channel.selected_feature_flags = inbox_update_params[:channel][:selected_feature_flags]
    @inbox.channel.save!
  end

  def permitted_params
    params.permit(:id, :avatar, :name, :greeting_message, :greeting_enabled, channel:
      [:type, :website_url, :widget_color, :welcome_title, :welcome_tagline, :webhook_url, :email])
  end

  def inbox_update_params
    params.permit(:enable_auto_assignment, :name, :avatar, :greeting_message, :greeting_enabled,
                  channel: [
                    :website_url,
                    :widget_color,
                    :welcome_title,
                    :welcome_tagline,
                    :webhook_url,
                    :email,
                    selected_feature_flags: []
                  ])
  end
end
