class AgentIdentity < Nightfury::Identity::Base
  metric :avg_first_response_time, :avg_time_series, store_as: :d, step: :day
  metric :avg_resolution_time, :avg_time_series, store_as: :f, step: :day
  metric :resolutions_count, :count_time_series, store_as: :g, step: :day
  tag :account_id, store_as: :co
end

AgentIdentity.store_as = :ai
