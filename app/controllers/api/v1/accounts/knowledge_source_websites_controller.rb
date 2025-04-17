require 'uri'

class Api::V1::Accounts::KnowledgeSourceWebsitesController < Api::V1::Accounts::BaseController
  before_action :set_ai_agent

  def create
    created_document_loader_ids = []
    scrapes = AiAgents::FirecrawlService.bulk_scrape(params[:links])

    knowledge_source = @ai_agent.knowledge_source
    raise ActiveRecord::Rollback, 'Knowledge source not found' if knowledge_source.nil?

    begin
      ActiveRecord::Base.transaction do
        scrapes.map! do |scrape|
          raise ActiveRecord::Rollback, 'Scrape is nil' if scrape.nil?

          document_loader = create_document_loader(knowledge_source.store_id, scrape[:url], scrape[:markdown])
          raise ActiveRecord::Rollback, 'Failed to create document loader' if document_loader.nil?

          created_document_loader_ids << document_loader['docId']

          parent_url = get_parent_url(scrape[:url])
          knowledge_source.knowledge_source_websites.add_record!(
            url: scrape[:url], parent_url: parent_url, content: scrape[:markdown], document_loader: document_loader
          )
        end
      end

      render json: scrapes.compact, status: :created
    rescue StandardError => e
      created_document_loader_ids.each do |id|
        delete_document_loader(store_id: knowledge_source.store_id, loader_id: id)
      end
      Rails.logger.error("Failed to create knowledge source websites: #{e.message}")
      render json: { error: e.message }, status: :bad_request
    end
  end

  def update
    knowledge_source = @ai_agent.knowledge_source
    return render json: { error: 'Knowledge source not found' }, status: :not_found if knowledge_source.nil?

    document_loader = create_document_loader(knowledge_source.store_id, params[:url], params[:markdown])
    return render json: { error: 'Failed to create document loader' }, status: :bad_request if document_loader.nil?

    begin
      update_record(knowledge_source, document_loader)
    rescue StandardError => e
      handle_update_failure(knowledge_source, document_loader, e)
    end
  end

  def destroy
    ids = params[:ids]
    return render json: { error: 'No links provided' }, status: :bad_request if ids.blank?

    knowledge_source = @ai_agent.knowledge_source
    knowledge_source_websites = knowledge_source.knowledge_source_websites.where(id: ids)

    knowledge_source_websites.each do |knowledge_source_website|
      knowledge_source_website.destroy
      delete_document_loader(store_id: knowledge_source.store_id, loader_id: knowledge_source_website.loader_id)
    end

    render json: { message: 'Knowledge source websites deleted successfully' }, status: :ok
  rescue StandardError => e
    Rails.logger.error("Failed to delete knowledge source websites: #{e.message}")
    render json: { error: 'Failed to delete knowledge source websites' }, status: :bad_request
  end

  def collect_link
    response = AiAgents::FirecrawlService.map(params[:url])
    render json: response, status: :ok
  end

  private

  def create_document_loader(store_id, name, text)
    AiAgents::FlowiseService.add_document_loader(
      store_id: store_id,
      loader_id: 'plainText',
      splitter_id: 'recursiveCharacterTextSplitter',
      name: name,
      content: text
    )
  rescue StandardError => e
    Rails.logger.error("Failed to add document loader: #{e.message}")
    nil
  end

  def update_record(knowledge_source, document_loader)
    result = knowledge_source.knowledge_source_websites.update_record!(
      params: params, document_loader: document_loader
    )
    delete_document_loader(store_id: knowledge_source.store_id, loader_id: result[:previous_loader_id])

    render json: result[:updated], status: :ok
  end

  def handle_update_failure(knowledge_source, document_loader, error)
    delete_document_loader(store_id: knowledge_source.store_id, loader_id: document_loader['docId'])
    Rails.logger.error("Failed to update knowledge source website: #{error.message}")
    render json: { error: 'Failed to update knowledge source website' }, status: :bad_request
  end

  def delete_document_loader(store_id:, loader_id:)
    AiAgents::FlowiseService.delete_document_loader(
      store_id: store_id,
      loader_id: loader_id
    )
  rescue StandardError => e
    Rails.logger.error("Failed to delete document loader: #{e.message}")
  end

  def get_parent_url(url)
    uri = URI.parse(url)
    "#{uri.scheme}://#{uri.host}"
  end

  def set_ai_agent
    @ai_agent = Current.account.ai_agents.find(params[:ai_agent_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'AI Agent not found' }, status: :not_found
  end
end
