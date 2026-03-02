# frozen_string_literal: true

class Saas::Api::V1::AiAgentsController < Api::V1::Accounts::BaseController
  before_action :set_ai_agent, only: [:show, :update, :destroy]
  before_action :authorize_ai_agent

  def index
    @ai_agents = Current.account.ai_agents
                        .includes(:inboxes, :knowledge_bases, :agent_tools)
                        .order(updated_at: :desc)
    render json: @ai_agents.map { |agent| agent_json(agent) }
  end

  def show
    render json: agent_json(@ai_agent, detailed: true)
  end

  def create
    @ai_agent = Current.account.ai_agents.new(ai_agent_params)
    if @ai_agent.save
      render json: agent_json(@ai_agent), status: :created
    else
      render json: { errors: @ai_agent.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @ai_agent.update(ai_agent_params)
      render json: agent_json(@ai_agent)
    else
      render json: { errors: @ai_agent.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @ai_agent.destroy!
    head :no_content
  end

  private

  def set_ai_agent
    @ai_agent = Current.account.ai_agents.find(params[:id])
  end

  def authorize_ai_agent
    authorize(@ai_agent || Saas::AiAgent)
  end

  def ai_agent_params
    params.require(:ai_agent).permit(
      :name, :description, :agent_type, :status, :model, :system_prompt,
      llm_config: {},
      voice_config: {},
      config: {}
    )
  end

  def agent_json(agent, detailed: false)
    data = agent_base_json(agent)
    data.merge!(agent_detail_json(agent)) if detailed
    data
  end

  def agent_base_json(agent)
    {
      id: agent.id, name: agent.name, description: agent.description,
      agent_type: agent.agent_type, status: agent.status, model: agent.model,
      system_prompt: agent.system_prompt, llm_config: agent.llm_config,
      voice_config: agent.voice_config, config: agent.config,
      inboxes_count: agent.inboxes.size, knowledge_bases_count: agent.knowledge_bases.size,
      tools_count: agent.agent_tools.size, created_at: agent.created_at, updated_at: agent.updated_at
    }
  end

  def agent_detail_json(agent)
    {
      inboxes: agent.ai_agent_inboxes.includes(:inbox).map { |link| inbox_link_json(link) },
      knowledge_bases: agent.knowledge_bases.map { |base| knowledge_base_summary(base) },
      tools: agent.agent_tools.map { |tool| tool_summary(tool) }
    }
  end

  def inbox_link_json(link)
    { id: link.id, inbox_id: link.inbox_id, inbox_name: link.inbox.name,
      auto_reply: link.auto_reply, status: link.status }
  end

  def knowledge_base_summary(base)
    { id: base.id, name: base.name, description: base.description, status: base.status,
      documents_count: base.knowledge_documents.count, ready_documents: base.ready_documents_count }
  end

  def tool_summary(tool)
    { id: tool.id, name: tool.name, description: tool.description,
      tool_type: tool.tool_type, http_method: tool.http_method, active: tool.active }
  end
end
