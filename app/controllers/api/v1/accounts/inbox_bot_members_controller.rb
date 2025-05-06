class Api::V1::Accounts::InboxBotMembersController < Api::V1::Accounts::BaseController
  before_action :fetch_inbox
  before_action :current_bot_ids, only: [:update]

  def show
    authorize @inbox, :show?

    ai_agents = @inbox.agent_bot_inboxes.includes(:ai_agent).map do |record|
      next unless record.ai_agent

      {
        id: record.ai_agent.id,
        name: record.ai_agent.name
      }
    end.compact

    render json: { payload: ai_agents }
  end

  def update
    authorize @inbox, :update?

    bot_ids = params[:bot_ids] || []

    ActiveRecord::Base.transaction do
      # Add or upsert agent bots
      bot_ids.each do |bot_id|
        AgentBotInbox.find_or_create_by!(
          inbox_id: @inbox.id,
          ai_agent_id: bot_id,
          status: 1,
          account_id: Current.account.id
        )
      end

      # Remove any that are no longer in the list
      AgentBotInbox
        .where(inbox_id: @inbox.id, account_id: Current.account.id)
        .where.not(ai_agent_id: bot_ids)
        .destroy_all
    end

    render json: bot_ids
  end

  private

  def fetch_inbox
    @inbox = Current.account.inboxes.find(params[:inbox_id])
  end

  def current_bot_ids
    @current_bot_ids = @inbox.agent_bot_inboxes.pluck(:ai_agent_id)
  end
end
