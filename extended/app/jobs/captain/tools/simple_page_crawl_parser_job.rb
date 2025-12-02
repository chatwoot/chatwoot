class Captain::Tools::SimplePageCrawlParserJob < ApplicationJob
  queue_as :low

  def perform(assistant_id:, page_link:)
    assistant = Captain::Assistant.find(assistant_id)
    account = assistant.account

    if limit_exceeded?(account)
      Rails.logger.info("Document limit exceeded for #{assistant_id}")
      return
    end

    crawler = Captain::Tools::SimplePageCrawlService.new(page_link)

    page_title = crawler.page_title || ''
    content = crawler.body_text_content || ''

    normalized_link = normalize_link(page_link)
    document = assistant.documents.find_or_initialize_by(external_link: normalized_link)

    document.update!(
      external_link: normalized_link,
      name: page_title[0..254], content: content[0..14_999], status: :available
    )
  rescue StandardError => e
    raise "Failed to parse data: #{page_link} #{e.message}"
  end

  private

  def normalize_link(raw_link)
    raw_link.to_s.delete_suffix('/')
  end

  def limit_exceeded?(account)
    limits = account.usage_limits[:captain][:documents]
    limits[:current_available].negative? || limits[:current_available].zero?
  end
end
