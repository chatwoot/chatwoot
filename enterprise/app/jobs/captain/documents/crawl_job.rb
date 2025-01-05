class Captain::Documents::CrawlJob < ApplicationJob
  queue_as :low

  def perform
    Captain::Documents::CrawlerService.new('https://www.example.com').perform
  end
end
