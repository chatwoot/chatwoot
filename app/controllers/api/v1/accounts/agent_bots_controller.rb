class Api::V1::Accounts::AgentBotsController < Api::V1::Accounts::BaseController
  before_action :current_account
  before_action :check_authorization
  before_action :agent_bot, except: [:index, :create]

  def index
    @agent_bots = AgentBot.accessible_to(Current.account)
  end

  def show; end

  def create
    @agent_bot = Current.account.agent_bots.create!(permitted_params.except(:avatar_url))
    process_avatar_from_url
  end

  def update
    update_params = permitted_params.except(:avatar_url)
    update_params.delete(:openai_api_key) if update_params[:openai_api_key].blank?
    update_params.delete(:google_api_key) if update_params[:google_api_key].blank?
    @agent_bot.update!(update_params)
    process_avatar_from_url
  end

  def avatar
    @agent_bot.avatar.purge if @agent_bot.avatar.attached?
    @agent_bot
  end

  def destroy
    @agent_bot.destroy!
    head :ok
  end

  def reset_access_token
    @agent_bot.access_token.regenerate_token
    @agent_bot.reload
  end

  private

  def agent_bot
    @agent_bot = AgentBot.accessible_to(Current.account).find(params[:id]) if params[:action] == 'show'
    @agent_bot ||= Current.account.agent_bots.find(params[:id])
  end

  def permitted_params
    permitted = params.permit(:name, :description, :outgoing_url, :avatar, :avatar_url, :bot_type, :openai_api_key, :google_api_key, bot_config: {})
    permitted[:assistant_config] = params[:assistant_config].to_unsafe_h if params[:assistant_config].present?
    permitted[:agent_behavior_config] = params[:agent_behavior_config].to_unsafe_h if params[:agent_behavior_config].present?
    permitted
  end

  def process_avatar_from_url
    ::Avatar::AvatarFromUrlJob.perform_later(@agent_bot, params[:avatar_url]) if params[:avatar_url].present?
  end
end
