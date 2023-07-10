# app/jobs/response_document_content_job.rb
class ResponseSourceJob < ApplicationJob
  queue_as :default

  def perform(response_source)
    CrawlerService.new(response_source).perform
  end
end
