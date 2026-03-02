# frozen_string_literal: true

class Saas::Api::V1::KnowledgeBasesController < Api::V1::Accounts::BaseController
  before_action :set_ai_agent
  before_action :set_knowledge_base, only: [:show, :update, :destroy]

  def index
    @knowledge_bases = @ai_agent.knowledge_bases.includes(:knowledge_documents)
    render json: @knowledge_bases.map { |kb| knowledge_base_json(kb) }
  end

  def show
    render json: knowledge_base_json(@knowledge_base, detailed: true)
  end

  def create
    @knowledge_base = @ai_agent.knowledge_bases.new(knowledge_base_params.merge(account: Current.account))
    if @knowledge_base.save
      render json: knowledge_base_json(@knowledge_base), status: :created
    else
      render json: { errors: @knowledge_base.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @knowledge_base.update(knowledge_base_params)
      render json: knowledge_base_json(@knowledge_base)
    else
      render json: { errors: @knowledge_base.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @knowledge_base.destroy!
    head :no_content
  end

  private

  def set_ai_agent
    @ai_agent = Current.account.ai_agents.find(params[:ai_agent_id])
  end

  def set_knowledge_base
    @knowledge_base = @ai_agent.knowledge_bases.find(params[:id])
  end

  def knowledge_base_params
    params.require(:knowledge_base).permit(:name, :description)
  end

  def knowledge_base_json(knowledge_base, detailed: false)
    data = {
      id: knowledge_base.id,
      name: knowledge_base.name,
      description: knowledge_base.description,
      status: knowledge_base.status,
      documents_count: knowledge_base.knowledge_documents.size,
      ready_documents: knowledge_base.ready_documents_count,
      created_at: knowledge_base.created_at,
      updated_at: knowledge_base.updated_at
    }

    if detailed
      data[:documents] = knowledge_base.knowledge_documents.map do |doc|
        { id: doc.id, title: doc.title, source_type: doc.source_type, source_url: doc.source_url,
          status: doc.status, content_type: doc.content_type, file_size: doc.file_size,
          chunk_count: doc.chunk_count, error_message: doc.error_message,
          created_at: doc.created_at }
      end
    end

    data
  end
end
