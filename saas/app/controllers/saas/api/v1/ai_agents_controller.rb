# frozen_string_literal: true

class Saas::Api::V1::AiAgentsController < Api::V1::Accounts::BaseController
  before_action :set_ai_agent, only: [:show, :update, :destroy, :preview, :voice_catalog, :voice_preview]
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
    return render_workflow_errors unless workflow_valid?

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

  # GET /ai_agents/:id/voice_catalog — list available voices and models for the provider
  def voice_catalog
    provider = params[:provider].presence || @ai_agent.voice_provider
    catalog = Voice::CatalogService.new(provider: provider)
    render json: { voices: catalog.voices, models: catalog.models }
  end

  # POST /ai_agents/:id/voice_preview — synthesize a short text sample
  def voice_preview
    provider = params[:provider].presence || @ai_agent.voice_provider
    catalog = Voice::CatalogService.new(provider: provider)
    audio = catalog.preview(
      voice_id: params[:voice_id],
      text: params[:text].presence || 'Hello! How can I help you today?',
      model_id: params[:model_id],
      language: params[:language]
    )
    if audio
      render json: { audio: audio, content_type: 'audio/mpeg' }
    else
      render json: { error: 'Preview unavailable' }, status: :unprocessable_entity
    end
  end

  # POST /ai_agents/:id/preview — test the agent without creating a real conversation
  def preview
    api_messages = build_preview_messages
    if preview_params[:stream]
      render json: enqueue_preview_stream(api_messages)
    else
      render json: execute_preview_chat(api_messages)
    end
  end

  private

  def set_ai_agent
    @ai_agent = Current.account.ai_agents.find(params[:id])
  end

  def authorize_ai_agent
    authorize(@ai_agent || Saas::AiAgent)
  end

  def build_preview_messages
    messages = preview_params[:messages] || []
    sections_builder = Agent::PromptSectionsBuilder.new(@ai_agent)
    system_prompt = sections_builder.sections? ? sections_builder.build : @ai_agent.system_prompt.presence || 'You are a helpful assistant.'

    api_messages = [{ role: 'system', content: system_prompt }]
    messages.each { |m| api_messages << { role: m['role'], content: m['content'] } }
    api_messages << { role: 'user', content: preview_params[:message] }
    api_messages
  end

  def enqueue_preview_stream(api_messages)
    request_id = SecureRandom.uuid
    LlmStreamJob.perform_later(
      current_account.id, request_id,
      { 'model' => @ai_agent.model, 'messages' => api_messages,
        'temperature' => @ai_agent.temperature, 'feature' => 'ai_agent_preview' }.compact
    )
    { request_id: request_id, stream: true }
  end

  def execute_preview_chat(api_messages)
    client = Llm::Client.new(model: @ai_agent.model)
    response = client.chat(messages: api_messages, temperature: @ai_agent.temperature)
    reply = response.dig('choices', 0, 'message', 'content') || ''
    { reply: reply, usage: response['usage'] }
  end

  def ai_agent_params
    params.require(:ai_agent).permit(
      :name, :description, :agent_type, :status, :model, :system_prompt,
      llm_config: {},
      voice_config: {},
      config: {},
      workflow: {}
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
      prompt_sections: agent.prompt_sections, has_prompt_sections: agent.has_prompt_sections?,
      workflow: agent.workflow, has_workflow: agent.has_workflow?,
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

  def workflow_valid?
    workflow_data = params.dig(:ai_agent, :workflow)
    return true if workflow_data.blank?

    validator = Agent::WorkflowValidator.new(workflow_data.to_unsafe_h)
    return true if validator.valid?

    @workflow_errors = validator.errors
    false
  end

  def render_workflow_errors
    render json: { errors: @workflow_errors }, status: :unprocessable_entity
  end

  def preview_params
    params.permit(:message, :stream, messages: [:role, :content])
  end
end
