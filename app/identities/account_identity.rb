class AccountIdentity < Nightfury::Identity::Base
  metric :conversations_count, :count_time_series, store_as: :b, step: :day
  metric :incoming_messages_count, :count_time_series, step: :day
  metric :outgoing_messages_count, :count_time_series, step: :day
  metric :avg_first_response_time, :avg_time_series, store_as: :d, step: :day
  metric :avg_resolution_time, :avg_time_series, store_as: :f, step: :day
  metric :resolutions_count, :count_time_series, store_as: :g, step: :day
end

AccountIdentity.store_as = :ci
