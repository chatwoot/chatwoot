class Captain::Tools::ContextDevPollJob < ApplicationJob
  queue_as :low

  POLL_DELAYS = [1.minute, 3.minutes, 8.minutes].freeze
  TERMINAL_STATUSES = %w[completed cancelled failed].freeze

  def self.schedule(document_id:, batch_id:)
    POLL_DELAYS.each do |delay|
      set(wait: delay).perform_later(document_id: document_id, batch_id: batch_id)
    end
  end

  def perform(document_id:, batch_id:)
    document = Captain::Document.find_by(id: document_id)
    return unless document&.web_crawling_external_id == batch_id

    status = WebCrawling::ContextDev::Spider.new.batch_status(batch_id: batch_id)
    return unless TERMINAL_STATUSES.include?(status)

    Captain::Tools::ContextDevParserJob.perform_later(
      document_id: document_id,
      batch_id: batch_id,
      event: "batch.#{status}"
    )
  end
end
