class Captain::Tools::FirecrawlParserJob < ApplicationJob
  queue_as :low

  def perform(assistant_id:, payload:)
    assistant = Captain::Assistant.find(assistant_id)
    metadata = payload[:metadata]

    canonical_url = normalize_link(metadata['url'])
    document = assistant.documents.find_or_initialize_by(
      external_link: canonical_url
    )

    document.update!(
      external_link: canonical_url,
      content: payload[:markdown],
      name: metadata['title'],
      status: :available
    )
  rescue StandardError => e
    raise "Failed to parse FireCrawl data: #{e.message}"
  end

  private

  def normalize_link(raw_url)
    raw_url.to_s.delete_suffix('/')
  end
end
