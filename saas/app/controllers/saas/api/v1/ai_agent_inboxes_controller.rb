# frozen_string_literal: true

class Saas::Api::V1::AiAgentInboxesController < Api::V1::Accounts::BaseController
  before_action :set_ai_agent
  before_action :set_ai_agent_inbox, only: [:update, :destroy]

  def create
    @ai_agent_inbox = @ai_agent.ai_agent_inboxes.new(inbox_params)
    if @ai_agent_inbox.save
      render json: inbox_json(@ai_agent_inbox), status: :created
    else
      render json: { errors: @ai_agent_inbox.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @ai_agent_inbox.update(inbox_params)
      render json: inbox_json(@ai_agent_inbox)
    else
      render json: { errors: @ai_agent_inbox.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @ai_agent_inbox.destroy!
    head :no_content
  end

  private

  def set_ai_agent
    @ai_agent = Current.account.ai_agents.find(params[:ai_agent_id])
  end

  def set_ai_agent_inbox
    @ai_agent_inbox = @ai_agent.ai_agent_inboxes.find(params[:id])
  end

  def inbox_params
    params.require(:ai_agent_inbox).permit(:inbox_id, :auto_reply, :status)
  end

  def inbox_json(agent_inbox)
    { id: agent_inbox.id, inbox_id: agent_inbox.inbox_id, inbox_name: agent_inbox.inbox.name,
      auto_reply: agent_inbox.auto_reply, status: agent_inbox.status }
  end
end
