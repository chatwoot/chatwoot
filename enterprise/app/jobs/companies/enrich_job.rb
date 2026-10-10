class Companies::EnrichJob < ApplicationJob
  queue_as :low

  def perform(company)
    Companies::EnrichmentService.new(company).perform
  end
end
