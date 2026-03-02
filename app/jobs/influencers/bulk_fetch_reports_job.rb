class Influencers::BulkFetchReportsJob < ApplicationJob
  queue_as :low
  DELAY_BETWEEN_REQUESTS = 2.seconds

  def perform(profile_ids)
    profile_ids.each_with_index do |profile_id, index|
      delay = index * DELAY_BETWEEN_REQUESTS
      Influencers::FetchReportJob.set(wait: delay).perform_later(profile_id)
    end
  end
end
