# app/jobs/response_document_content_job.rb
class ResponseBot::ResponseDocumentContentJob < ApplicationJob
  queue_as :default

  def perform(response_document)
    # Replace the selector with the actual one you need.
    content = PageCrawlerService.new(response_document.document_link).body_text_content
    response_document.update!(content: content[0..15_000])
  end
end
