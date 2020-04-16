class Api::V1::Accounts::InboxesController < Api::BaseController
  before_action :check_authorization
  before_action :fetch_inbox, except: [:index]
  before_action :fetch_agent_bot, only: [:set_agent_bot]

  def index
    @inboxes = policy_scope(current_account.inboxes)
  end

  def update
    @inbox.update(inbox_update_params)
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
    @inbox = current_account.inboxes.find(params[:id])
  end

  def fetch_agent_bot
    @agent_bot = AgentBot.find(params[:agent_bot]) if params[:agent_bot]
  end

  def check_authorization
    authorize(Inbox)
  end

  def inbox_update_params
    params.require(:inbox).permit(:enable_auto_assignment, :avatar)
  end
end
