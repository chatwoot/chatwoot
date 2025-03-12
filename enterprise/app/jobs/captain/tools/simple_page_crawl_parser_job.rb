class Captain::Tools::SimplePageCrawlParserJob < ApplicationJob
  queue_as :low

  def perform(assistant_id:, page_link:)
    assistant = Captain::Assistant.find(assistant_id)
    crawler = Captain::Tools::SimplePageCrawlService.new(page_link)

    page_title = crawler.page_title || ''
    content = crawler.body_text_content || ''

    document = assistant.documents.find_or_initialize_by(
      external_link: page_link
    )

    document.update!(
      name: page_title[0..254], content: content[0..14_999], status: :available
    )
  rescue StandardError => e
    raise "Failed to parse data: #{page_link} #{e.message}"
  end
end
