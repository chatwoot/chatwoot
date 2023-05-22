class CustomFilterRecordsCountUpdateJob < ApplicationJob
  queue_as :low

  def perform
    CustomFilter.find_each(batch_size: 25) do |filter|
      next if filter.fetch_record_count_from_redis.nil?

      filter.set_records_count
    end
  end
end
