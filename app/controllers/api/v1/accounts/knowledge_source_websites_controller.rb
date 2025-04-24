require 'uri'

class Api::V1::Accounts::KnowledgeSourceWebsitesController < Api::V1::Accounts::BaseController
  before_action :set_ai_agent

  def create
    return render_error('Knowledge source not found') if find_knowledge_source.nil?

    created_document_loader_ids = []

    begin
      scrapes = fetch_scraped_content
    rescue StandardError => e
      return render_error(e.message)
    end

    begin
      processed_scrapes = process_scrapes(find_knowledge_source, scrapes, created_document_loader_ids)
      upsert_document_store(find_knowledge_source) if find_knowledge_source.not_empty?
      # If the knowledge source is empty, we don't need to upsert the document store
      # because it will be deleted in the destroy method of the knowledge source.
      render json: processed_scrapes.compact, status: :created
    rescue StandardError => e
      cleanup_created_loaders(find_knowledge_source.store_id, created_document_loader_ids)
      handle_error('Failed to create knowledge source websites', e)
    end
  end

  def update
    return render json: { error: 'Knowledge source not found' }, status: :not_found if find_knowledge_source.nil?

    document_loader = create_document_loader(find_knowledge_source.store_id, params[:url], params[:markdown])
    return render json: { error: 'Failed to create document loader' }, status: :bad_request if document_loader.nil?

    begin
      update_record(find_knowledge_source, document_loader)
    rescue StandardError => e
      handle_update_failure(find_knowledge_source, document_loader, e)
    end
  end

  def destroy
    return render json: { error: 'No links provided' }, status: :bad_request if params[:ids].blank?

    knowledge_source_websites = find_knowledge_source.knowledge_source_websites.where(id: params[:ids])
    return render json: { error: 'No matching knowledge source websites found' }, status: :not_found if knowledge_source_websites.blank?

    ActiveRecord::Base.transaction do
      knowledge_source_websites.each(&:destroy!)
    end

    knowledge_source_websites.each do |knowledge_source_website|
      delete_document_loader(store_id: find_knowledge_source.store_id, loader_id: knowledge_source_website.loader_id)
    end

    upsert_document_store(find_knowledge_source) if find_knowledge_source.not_empty?

    render json: { message: 'Knowledge source websites deleted successfully' }, status: :ok
  rescue StandardError => e
    handle_error('Failed to delete knowledge source websites', e)
  end

  def collect_link
    response = AiAgents::FirecrawlService.map(params[:url])
    render json: response, status: :ok
  rescue StandardError => e
    handle_error('Failed to collect link', e)
  end

  private

  def fetch_scraped_content
    AiAgents::FirecrawlService.bulk_scrape(params[:links])
  end

  def process_scrapes(knowledge_source, scrapes, created_ids_array)
    document_loaders = process_scrape_to_create_document_loader(knowledge_source, scrapes)

    ActiveRecord::Base.transaction do
      scrapes.map do |scrape|
        process_single_scrape(knowledge_source, scrape, document_loaders, created_ids_array)
      end
    end

    scrapes
  end

  def process_scrape_to_create_document_loader(knowledge_source, scrapes)
    scrapes.map do |scrape|
      document_loader = create_document_loader(
        knowledge_source.store_id,
        scrape[:url],
        scrape[:markdown]
      )
      raise StandardError, "Failed to create document loader for scrape #{scrape[:url]}" if document_loader.nil?

      document_loader
    end
  end

  def process_single_scrape(knowledge_source, scrape, document_loaders, created_ids_array)
    return nil if scrape.nil?

    found_loader = document_loaders.find { |loader| loader.dig('file', 'loaderName') == scrape[:url] }
    return nil if found_loader.nil?

    Rails.logger.info("Found loader: #{found_loader}")

    created_ids_array << found_loader['docId']
    create_knowledge_source_website(knowledge_source, scrape, found_loader)

    scrape
  end

  def create_knowledge_source_website(knowledge_source, scrape, document_loader)
    parent_url = get_parent_url(scrape[:url])

    knowledge_source.knowledge_source_websites.add_record!(
      url: scrape[:url],
      parent_url: parent_url,
      content: scrape[:markdown],
      document_loader: document_loader
    )
  end

  def cleanup_created_loaders(store_id, loader_ids)
    loader_ids.each do |id|
      delete_document_loader(store_id: store_id, loader_id: id)
    end
  end

  def handle_error(message, exception)
    Rails.logger.error("#{message}: #{exception.message}")
    render_error(message)
  end

  def render_error(message, status = :bad_request)
    render json: { error: message }, status: status
  end

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
    upsert_document_store(knowledge_source) if knowledge_source.not_empty?
    # If the knowledge source is empty, we don't need to upsert the document store
    # because it will be deleted in the destroy method of the knowledge source.

    render json: result[:updated], status: :ok
  end

  def handle_update_failure(knowledge_source, document_loader, error)
    delete_document_loader(store_id: knowledge_source.store_id, loader_id: document_loader['docId'])
    handle_error('Failed to update knowledge source website', error)
  end

  def delete_document_loader(store_id:, loader_id:)
    AiAgents::FlowiseService.delete_document_loader(
      store_id: store_id,
      loader_id: loader_id
    )
  rescue StandardError => e
    Rails.logger.error("Failed to delete document loader: #{e.message}")
  end

  def upsert_document_store(knowledge_source)
    AiAgents::FlowiseService.upsert_document_store(knowledge_source.store_config)
  end

  def get_parent_url(url)
    uri = URI.parse(url)
    "#{uri.scheme}://#{uri.host}"
  end

  def find_knowledge_source
    @find_knowledge_source ||= @ai_agent.knowledge_source
  end

  def set_ai_agent
    @ai_agent = Current.account.ai_agents.find(params[:ai_agent_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'AI Agent not found' }, status: :not_found
  end
end
