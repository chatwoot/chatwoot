require 'uri'

class Api::V1::Accounts::KnowledgeSourceWebsitesController < Api::V1::Accounts::BaseController
  before_action :set_ai_agent

  def create
    scrapes = AiAgents::FirecrawlService.bulk_scrape(params[:links])
    scrapes.map! do |scrape|
      next unless scrape

      knowledge_source = @ai_agent.knowledge_source
      next unless knowledge_source

      document_loader = create_document_loader(knowledge_source.store_id, scrape[:url], scrape[:markdown])
      next unless document_loader

      parent_url = get_parent_url(scrape[:url])

      begin
        knowledge_source.add_website!(url: scrape[:url], parent_url: parent_url, content: scrape[:markdown], document_loader: document_loader)
      rescue StandardError => e
        delete_document_loader(store_id: knowledge_source.store_id, loader_id: document_loader['docId'])
        Rails.logger.error("Failed to create knowledge source: #{e.message}")
      end
    end
    render json: scrapes.compact, status: :created
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
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Knowledge source not found' }, status: :not_found
  rescue StandardError => e
    Rails.logger.error("Failed to delete knowledge source websites: #{e.message}")
    render json: { error: 'Failed to delete knowledge source websites' }, status: :unprocessable_entity
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
