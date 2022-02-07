class Api::V1::Accounts::AgentBotsController < Api::V1::Accounts::BaseController
  before_action :current_account
  before_action :check_authorization
  before_action :agent_bot, except: [:index, :create]

  def index
    @agent_bots = AgentBot.where(account_id: [nil, Current.account.id])
  end

  def show; end

  def create
    @agent_bot = Current.account.agent_bots.create!(permitted_params)
  end

  def update
    @agent_bot.update!(permitted_params)
  end

  def destroy
    @agent_bot.destroy
    head :ok
  end

  private

  def agent_bot
    @agent_bot = AgentBot.where(account_id: [nil, Current.account.id]).find(params[:id]) if params[:action] == 'show'
    @agent_bot ||= Current.account.agent_bots.find(params[:id])
  end

  def permitted_params
    params.permit(:name, :description, :outgoing_url)
  end
end
