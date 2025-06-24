class Captain::Tools::NotionCrawlParserJob < ApplicationJob
  queue_as :low

  def perform(assistant_id:, page_id:)
    assistant = Captain::Assistant.find(assistant_id)
    account = assistant.account

    if limit_exceeded?(account)
      Rails.logger.info("Document limit exceeded for assistant #{assistant_id}")
      return
    end

    processor_service = Integrations::Notion::ProcessorService.new(account: account)
    page_data = processor_service.full_page(page_id)

    if page_data[:error]
      Rails.logger.error("Failed to fetch Notion page #{page_id}: #{page_data[:error]}")
      return
    end

    page_title = page_data['title'] || ''
    content = page_data['md'] || ''
    page_url = page_data['url'] || ''

    document = assistant.documents.find_or_initialize_by(
      external_id: page_id,
      document_type: :notion
    )

    document.update!(
      name: page_title[0..254],
      content: content[0..199_999],
      external_link: page_url,
      status: :available
    )
  rescue StandardError => e
    Rails.logger.error("Failed to parse Notion page: #{page_id} - #{e.message}")
    raise "Failed to parse Notion page: #{page_id} #{e.message}"
  end

  private

  def limit_exceeded?(account)
    limits = account.usage_limits[:captain][:documents]
    limits[:current_available].negative? || limits[:current_available].zero?
  end
end