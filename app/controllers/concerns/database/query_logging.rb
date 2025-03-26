module Database::QueryLogging
  extend ActiveSupport::Concern

  private

  def log_query_details(query_info, index)
    Rails.logger.error "Query ##{index + 1} [PID: #{query_info[:pid]}] [Duration: #{query_info[:duration]}] [State: #{query_info[:state]}]:"
    Rails.logger.error "App: #{query_info[:application_name]} User: #{query_info[:username]} Client: #{query_info[:client_addr]}"
    Rails.logger.error "Waiting: #{query_info[:wait_event_type]} / #{query_info[:wait_event]}" if query_info[:wait_event_type].present?
    Rails.logger.error query_info[:query]
  end

  def log_active_queries(active_queries)
    if active_queries.any?
      Rails.logger.error "Active Database Queries (#{active_queries.count}):"
      active_queries.each_with_index { |query_info, index| log_query_details(query_info, index) }
    else
      Rails.logger.error 'No active queries found or unable to retrieve query information'
    end
  end

  def log_locked_queries(locked_queries)
    return if locked_queries.blank?

    Rails.logger.error "Locked Queries (#{locked_queries.count}):"
    locked_queries.each_with_index do |lock_info, index|
      Rails.logger.error "Lock ##{index + 1}: PID #{lock_info[:blocked_pid]} blocked by PID #{lock_info[:blocking_pid]}"
      Rails.logger.error "Duration: #{lock_info[:blocking_duration]}"
      Rails.logger.error "Blocked query: #{lock_info[:blocked_statement]}"
      Rails.logger.error "Blocking query: #{lock_info[:blocking_statement]}"
    end
  end
end
