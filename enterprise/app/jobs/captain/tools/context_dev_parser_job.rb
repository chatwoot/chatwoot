class Captain::Tools::ContextDevParserJob < ApplicationJob
  queue_as :low

  def perform(document_id:, batch_id:, event:, cursor: nil)
    source_document = Captain::Document.find(document_id)
    return unless source_document.web_crawling_external_id == batch_id

    return fail_submission(source_document) unless event == 'batch.completed'

    results = WebCrawling::ContextDev::Spider.new.fetch_results(batch_id: batch_id, cursor: cursor)
    results.pages.each { |page| persist_page(source_document.assistant, page) }

    if results.has_more
      self.class.perform_later(document_id: document_id, batch_id: batch_id, event: event, cursor: results.next_cursor)
    else
      clear_submission(source_document)
    end
  end

  private

  def persist_page(assistant, page)
    external_link = page.url.to_s.delete_suffix('/')
    document = assistant.documents.find_by(external_link: external_link)

    if page.error_code
      mark_failed(document, page.error_code) if document
      return
    end

    document ||= assistant.documents.build(external_link: external_link)
    document.update!(
      name: page.title.to_s.truncate(255, omission: ''),
      content: page.markdown.to_s.truncate(200_000, omission: ''),
      status: :available,
      sync_status: :synced,
      last_synced_at: Time.current,
      last_sync_attempted_at: Time.current,
      last_sync_error_code: nil
    )
  end

  def fail_submission(document)
    mark_failed(document, 'fetch_failed')
    clear_submission(document)
  end

  def mark_failed(document, error_code)
    document.update!(
      status: :available,
      sync_status: :failed,
      last_sync_error_code: error_code,
      last_sync_attempted_at: Time.current
    )
  end

  def clear_submission(document)
    document.reload
    document.update!(
      web_crawling_provider: nil,
      web_crawling_external_id: nil,
      web_crawling_webhook_secret: nil
    )
  end
end
