json.array! @statistics do |statistic|
  json.date statistic.date
  json.total_queued statistic.total_queued
  json.total_assigned statistic.total_assigned
  json.total_left statistic.total_left
  json.average_wait_time_seconds statistic.average_wait_time_seconds
  json.max_wait_time_seconds statistic.max_wait_time_seconds
  json.average_wait_time_minutes (statistic.average_wait_time_seconds / 60.0).round(2)
  json.max_wait_time_minutes (statistic.max_wait_time_seconds / 60.0).round(2)
end
