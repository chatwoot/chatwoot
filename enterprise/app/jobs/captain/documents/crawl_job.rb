class Captain::Documents::CrawlJob < ApplicationJob
  queue_as :low

  def perform(document)
    webhook_url = Rails.application.routes.url_helpers.enterprise_webhooks_firecrawl_url

    Captain::Tools::FirecrawlService
      .new
      .perform(
        document.external_link,
        "#{webhook_url}?assistant_id=#{document.assistant_id}"
      )
  end
end
