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
      Rails.logger.error("Error: #{e.class} - #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      cleanup_created_loaders(find_knowledge_source.store_id, created_document_loader_ids)
      handle_error('Failed to create knowledge source websites', e)
    end
  end

  def update
    return render json: { error: 'Knowledge source not found' }, status: :not_found if find_knowledge_source.nil?

    scrapes = [
      {
        url: params[:url],
        markdown: params[:markdown]
      }
    ]

    created_document_loader_ids = []

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

  def destroy # rubocop:disable Metrics/AbcSize
    return render json: { error: 'No links provided' }, status: :bad_request if params[:ids].blank?

    knowledge_source_websites = find_knowledge_source.knowledge_source_websites.where(id: params[:ids])
    return render json: { error: 'No matching knowledge source websites found' }, status: :not_found if knowledge_source_websites.blank?

    ActiveRecord::Base.transaction do
      knowledge_source_websites.each(&:destroy!)
    end

    document_loader_ids = knowledge_source_websites.flat_map do |website|
      [website.loader_id, *website.loader_ids]
    end.compact.uniq

    cleanup_created_loaders(find_knowledge_source.store_id, document_loader_ids)
    upsert_document_store(find_knowledge_source) if find_knowledge_source.not_empty?

    render json: { message: 'Knowledge source websites deleted successfully' }, status: :ok
  rescue StandardError => e
    handle_error('Failed to delete knowledge source websites', e)
  end

  def collect_link
    response = Crawl4ai::MapService.new(links: [params[:url]]).perform
    render json: response, status: :ok
  rescue StandardError => e
    handle_error('Failed to collect link', e)
  end

  private

  def fetch_scraped_content
    Crawl4ai::CrawlService.new(links: params[:links]).perform
  end

  def process_scrapes(knowledge_source, scrapes, created_ids_array)
    store_id = knowledge_source.store_id
    document_loaders = process_scrape_to_create_document_loader(store_id, scrapes)

    ActiveRecord::Base.transaction do
      scrapes.map do |scrape|
        process_single_scrape(knowledge_source, scrape, document_loaders, created_ids_array)
      end
    end

    scrapes
  end

  def process_scrape_to_create_document_loader(store_id, scrapes)
    scrapes.map do |scrape|
      url = scrape[:url]
      markdown = scrape[:markdown]

      chunks = markdown.chars.each_slice(10_000).map(&:join)

      chunks.map.with_index do |chunk, _index|
        Rails.logger.info("Chunk: #{chunk}")
        document_loader = create_document_loader(store_id, url, chunk)
        if document_loader.nil?
          raise StandardError,
                "Failed to create document loader for scrape #{scrape[:url]} batch #{idx + 1}"
        end

        document_loader
      end
    end
  end

  def process_single_scrape(knowledge_source, scrape, document_loaders, created_ids_array)
    return nil if scrape.nil?

    document_loaders = document_loaders.flatten
    matched_loaders = document_loaders.select { |loader| loader.dig('file', 'loaderName') == scrape[:url] }
    return nil if matched_loaders.empty?

    loader_ids = matched_loaders.pluck('docId')
    created_ids_array.concat(loader_ids)

    total_chars = matched_loaders.sum { |loader| loader['characters'].to_i }
    total_chunks  = matched_loaders.sum { |loader| loader.dig('file', 'totalChunks').to_i }

    create_knowledge_source_website(knowledge_source, scrape, loader_ids, total_chars, total_chunks)

    scrape
  end

  def create_knowledge_source_website(knowledge_source, scrape, loader_ids, total_chars, total_chunks)
    parent_url = get_parent_url(scrape[:url])

    knowledge_source.knowledge_source_websites.create!(
      url: scrape[:url],
      parent_url: parent_url,
      content: scrape[:markdown].to_s,
      loader_id: loader_ids.first,
      loader_ids: loader_ids,
      total_chars: total_chars,
      total_chunks: total_chunks
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
    render json: { error: message, message: message }, status: status
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
