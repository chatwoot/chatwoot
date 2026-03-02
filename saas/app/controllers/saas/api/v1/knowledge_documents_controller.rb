# frozen_string_literal: true

class Saas::Api::V1::KnowledgeDocumentsController < Api::V1::Accounts::BaseController
  before_action :set_ai_agent
  before_action :set_knowledge_base
  before_action :set_document, only: [:destroy]

  def create
    @document = @knowledge_base.knowledge_documents.new(document_params.merge(account: Current.account))
    if @document.save
      Rag::DocumentIngestionJob.perform_later(@document.id) if @document.pending?
      render json: document_json(@document), status: :created
    else
      render json: { errors: @document.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @document.destroy!
    head :no_content
  end

  private

  def set_ai_agent
    @ai_agent = Current.account.ai_agents.find(params[:ai_agent_id])
  end

  def set_knowledge_base
    @knowledge_base = @ai_agent.knowledge_bases.find(params[:knowledge_base_id])
  end

  def set_document
    @document = @knowledge_base.knowledge_documents.find(params[:id])
  end

  def document_params
    params.require(:knowledge_document).permit(:title, :source_type, :source_url, :content)
  end

  def document_json(doc)
    { id: doc.id, title: doc.title, source_type: doc.source_type, source_url: doc.source_url,
      status: doc.status, content_type: doc.content_type, file_size: doc.file_size,
      chunk_count: doc.chunk_count, error_message: doc.error_message, created_at: doc.created_at }
  end
end
