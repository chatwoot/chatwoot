class SyncCustomFilterCountJob < ApplicationJob
  queue_as :low

  def perform(filter)
    Redis::Alfred.set(filter.filter_count_key, 0) if filter.filter_records.nil?

    filter.set_record_count_in_redis
  end
end
