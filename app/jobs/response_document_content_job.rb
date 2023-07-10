# app/jobs/response_document_content_job.rb
class ResponseDocumentContentJob < ApplicationJob
  queue_as :default

  def perform(response_document)
    session = Capybara::Session.new(:selenium)
    session.visit(response_document.document_link)

    # Replace the selector with the actual one you need.
    content = session.find('body').text
    response_document.update!(content: content[0..15_000])
  end
end
