class CustomFiltersRecordsCountUpdateJob < ApplicationJob
  queue_as :low

  def perform
    CustomFilter.find_each(batch_size: 25) do |filter|
      SyncCustomFilterCountJob.perform_later(filter)
    end
  end
end
