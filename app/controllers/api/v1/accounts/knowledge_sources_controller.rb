class Api::V1::Accounts::KnowledgeSourcesController < Api::V1::Accounts::BaseController
  before_action :set_ai_agent

  def index
    @knowledge_source = @ai_agent.knowledge_source

    if @knowledge_source
      render json: @knowledge_source.as_json(include:
      [
        :knowledge_source_texts,
        :knowledge_source_files,
        :knowledge_source_websites
      ]), status: :ok
    else
      render json: { error: 'Knowledge source not found' }, status: :not_found
    end
  end

  def set_ai_agent
    @ai_agent = Current.account.ai_agents
                       .includes(knowledge_source: :knowledge_source_texts)
                       .find(params[:ai_agent_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'AI Agent not found' }, status: :not_found
  end
end
