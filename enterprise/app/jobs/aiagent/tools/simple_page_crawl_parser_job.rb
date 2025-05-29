class Aiagent::Tools::SimplePageCrawlParserJob < ApplicationJob
  queue_as :low

  def perform(topic_id:, page_link:)
    topic = Aiagent::Topic.find(topic_id)
    account = topic.account

    if limit_exceeded?(account)
      Rails.logger.info("Document limit exceeded for #{topic_id}")
      return
    end

    crawler = Aiagent::Tools::SimplePageCrawlService.new(page_link)

    page_title = crawler.page_title || ''
    content = crawler.body_text_content || ''

    document = topic.documents.find_or_initialize_by(
      external_link: page_link
    )

    document.update!(
      name: page_title[0..254], content: content[0..14_999], status: :available
    )
  rescue StandardError => e
    raise "Failed to parse data: #{page_link} #{e.message}"
  end

  private

  def limit_exceeded?(account)
    limits = account.usage_limits[:aiagent][:documents]
    limits[:current_available].negative? || limits[:current_available].zero?
  end
end
