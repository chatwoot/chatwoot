class SyncCustomFilterCountJob < ApplicationJob
  queue_as :low

  def perform(filter)
    return if filter.fetch_record_count_from_redis.nil?

    filter.set_records_count
  end
end
