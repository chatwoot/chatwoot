# Backoffable provides transient-error retry backoff for models that depend on external services.
#
# When a transient error occurs (network hiccup, SSL failure, etc.) call apply_backoff!.
# The wait time ramps from 1 minute up to BACKOFF_MAX_INTERVAL_MINUTES, then holds at that
# ceiling for BACKOFF_MAX_INTERVAL_COUNT more attempts before calling prompt_reauthorization!.
#
# Call clear_backoff! after a successful operation to reset the counter.

module Backoffable
  extend ActiveSupport::Concern

  def backoff_log_identifier
    inbox_id = respond_to?(:inbox) && inbox&.id
    inbox_id ? "#{self.class.name} - #{inbox_id}" : "#{self.class.name}##{id}"
  end

  def backoff_retry_count
    ::Redis::Alfred.get(backoff_retry_count_key).to_i
  end

  def in_backoff?
    val = ::Redis::Alfred.get(backoff_retry_after_key)
    val.present? && Time.zone.at(val.to_f) > Time.current
  end

  def apply_backoff!
    new_count = backoff_retry_count + 1
    max_interval, max_retries = backoff_limits

    if new_count > max_retries
      exhaust_backoff(new_count)
    else
      schedule_backoff_retry(new_count, max_interval, max_retries)
    end
  end

  def clear_backoff!
    ::Redis::Alfred.delete(backoff_retry_count_key)
    ::Redis::Alfred.delete(backoff_retry_after_key)
  end

  private

  def backoff_limits
    max_interval = GlobalConfigService.load('BACKOFF_MAX_INTERVAL_MINUTES', 5).to_i
    max_count    = GlobalConfigService.load('BACKOFF_MAX_INTERVAL_COUNT', 10).to_i
    [max_interval, (max_interval - 1) + max_count]
  end

  def exhaust_backoff(new_count)
    Rails.logger.warn "#{backoff_log_identifier} backoff exhausted (#{new_count} failures), prompting reauthorization"
    clear_backoff!
    prompt_reauthorization!
  end

  def schedule_backoff_retry(new_count, max_interval, max_retries)
    wait_minutes = [new_count, max_interval].min
    ::Redis::Alfred.set(backoff_retry_count_key, new_count.to_s, ex: 24.hours)
    ::Redis::Alfred.set(backoff_retry_after_key, wait_minutes.minutes.from_now.to_f.to_s, ex: 24.hours)
    Rails.logger.warn "#{backoff_log_identifier} backoff retry #{new_count}/#{max_retries}, next attempt in #{wait_minutes}m"
  end

  def backoff_retry_count_key
    format(::Redis::Alfred::BACKOFF_RETRY_COUNT, obj_type: self.class.table_name.singularize, obj_id: id)
  end

  def backoff_retry_after_key
    format(::Redis::Alfred::BACKOFF_RETRY_AFTER, obj_type: self.class.table_name.singularize, obj_id: id)
  end
end
