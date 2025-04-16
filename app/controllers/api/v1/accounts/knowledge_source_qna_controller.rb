class Api::V1::Accounts::KnowledgeSourceQnaController < Api::V1::Accounts::BaseController
  before_action :set_ai_agent

  def create
    knowledge_source = @ai_agent.knowledge_source
    unless knowledge_source
      render json: { error: 'Knowledge source not found' }, status: :not_found
      return
    end

    create_source(knowledge_source)
  end

  def destroy
    knowledge_source = @ai_agent.knowledge_source
    knowledge_source_qna = knowledge_source.knowledge_source_qnas.find(params[:id])

    if knowledge_source_qna.destroy
      delete_document_loader(store_id: knowledge_source.store_id, loader_id: knowledge_source_qna.loader_id)

      head :no_content
    else
      render json: { error: 'Failed to delete knowledge source qna' }, status: :unprocessable_entity
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
          document_loader = create_document_loader(
            knowledge_source.store_id,
            "QNA_#{Time.current.strftime('%Y%m%d%H%M%S')}",
            "#{qna[:question]}\n\n#{qna[:answer]}"
          )
          successful_loaders << document_loader['docId']

          result = knowledge_source.knowledge_source_qnas.create_or_update(
            qna_param: qna,
            document_loader: document_loader
          )

          created_or_updated_qnas << result[:qna]
          previous_loader_ids_to_delete << result[:previous_loader_id] if result[:previous_loader_id].present?
        end
      end

      previous_loader_ids_to_delete.each do |old_loader_id|
        delete_document_loader(store_id: knowledge_source.store_id, loader_id: old_loader_id)
      end

      render json: created_or_updated_qnas, status: :created
    rescue StandardError => e
      successful_loaders.each do |id|
        delete_document_loader(store_id: knowledge_source.store_id, loader_id: id)
      end

      render json: { error: e.message }, status: :bad_gateway
    end
  end

  def create_document_loader(store_id, name, text)
    AiAgents::FlowiseService.add_document_loader(
      store_id: store_id,
      loader_id: 'plainText',
      splitter_id: '',
      name: name,
      content: text
    )
  end

  def delete_document_loader(store_id:, loader_id:)
    AiAgents::FlowiseService.delete_document_loader(
      store_id: store_id,
      loader_id: loader_id
    )
  rescue StandardError => e
    Rails.logger.error("Failed to delete document loader: #{e.message}")
  end

  def set_ai_agent
    @ai_agent = Current.account.ai_agents.find(params[:ai_agent_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'AI Agent not found' }, status: :not_found
  end

  def qna_params
    params.require(:_json).map do |q|
      q.permit(:id, :question, :answer)
    end
  end
end
