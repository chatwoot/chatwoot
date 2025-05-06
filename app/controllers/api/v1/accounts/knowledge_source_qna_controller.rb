class Api::V1::Accounts::KnowledgeSourceQnaController < Api::V1::Accounts::BaseController
  before_action :set_ai_agent

  def create
    knowledge_source = @ai_agent.knowledge_source
    unless knowledge_source
      handle_error('Knowledge source not found')
      return
    end

    create_source(knowledge_source)
    upsert_document_store(knowledge_source)
  end

  def destroy
    knowledge_source = @ai_agent.knowledge_source
    knowledge_source_qna = knowledge_source.knowledge_source_qnas.find(params[:id])

    if knowledge_source_qna.destroy
      delete_document_loaders(knowledge_source.store_id, [knowledge_source_qna.loader_id])
      upsert_document_store(knowledge_source) if knowledge_source.not_empty?
      # If the knowledge source is empty, we don't need to upsert the document store
      # because it will be deleted in the destroy method of the knowledge source.

      head :no_content
    else
      handle_error('Failed to delete knowledge source')
    end
  end

  private

  def create_source(knowledge_source)
    successful_loaders = []
    created_or_updated_qnas = []
    previous_loader_ids_to_delete = []

    begin
      ActiveRecord::Base.transaction do
        qna_params.each do |qna|
          document_loader = create_document_loader(knowledge_source.store_id, qna)
          successful_loaders << document_loader['docId']

          result = knowledge_source.knowledge_source_qnas.create_or_update(qna, document_loader)

          created_or_updated_qnas << result[:qna]
          previous_loader_ids_to_delete << result[:previous_loader_id] if result[:previous_loader_id].present?
        end
      end

      delete_document_loaders(knowledge_source.store_id, previous_loader_ids_to_delete) if previous_loader_ids_to_delete.present?

      render json: created_or_updated_qnas, status: :created
    rescue StandardError => e
      delete_document_loaders(knowledge_source.store_id, successful_loaders) if successful_loaders.present?
      handle_error('Failed to create knowledge source qna', status: :bad_gateway, exception: e)
    end
  end

  def create_document_loader(store_id, content)
    AiAgents::FlowiseService.add_document_loader(
      store_id: store_id,
      loader_id: 'plainText',
      splitter_id: '',
      name: "QNA_#{Time.current.strftime('%Y%m%d%H%M%S')}",
      content: "#{content[:question]}\n\n#{content[:answer]}"
    )
  end

  def delete_document_loaders(store_id, loader_ids)
    failed_deletes = []

    Array(loader_ids).each do |loader_id|
      AiAgents::FlowiseService.delete_document_loader(
        store_id: store_id,
        loader_id: loader_id
      )
    rescue StandardError => e
      Rails.logger.error("Failed to delete document loader #{loader_id}: #{e.message}")
      failed_deletes << loader_id
    end

    return unless failed_deletes.any?

    Rails.logger.warn("Some document loaders failed to delete: #{failed_deletes.join(', ')}")
  end

  def upsert_document_store(knowledge_source)
    AiAgents::FlowiseService.upsert_document_store(knowledge_source.store_config)
  end

  def handle_error(message, status: :bad_request, exception: nil)
    Rails.logger.error("#{message}: #{exception&.message}") # Use safe navigation operator
    render_error(message, status)
  end

  def render_error(message, status = :bad_request)
    render json: { error: message }, status: status
  end

  def set_ai_agent
    @ai_agent = Current.account.ai_agents.find(params[:ai_agent_id])
  rescue ActiveRecord::RecordNotFound
    handle_error('AI Agent not found', :not_found)
  end

  def qna_params
    params.require(:_json).map do |qna|
      qna.permit(:id, :question, :answer)
    end
  end
end
