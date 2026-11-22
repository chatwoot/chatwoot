require 'digest'

# Tracks IMAP messages that failed while being processed. The fetch service
# consults this BEFORE downloading the message body, so a known-failing message
# is not re-downloaded on every run. Failures are retried with a short backoff
# and the message is skipped entirely once the retries are exhausted.
class Imap::FailedMessageTracker
  MAX_FAILURES = 3
  RETRY_BACKOFF = [5.minutes, 20.minutes].freeze
  TTL = 6.hours.to_i

  pattr_initialize [:inbox!]

  def skip?(source_id)
    state = read_state(source_id)
    return false if state.blank?
    return true if state['failures'] >= MAX_FAILURES

    Time.now.to_i - state['last_failed_at'] < retry_delay(state['failures'])
  end

  # Returns the total number of failures recorded for the message.
  def record_failure(source_id)
    failures = read_state(source_id)['failures'].to_i + 1
    payload = { failures: failures, last_failed_at: Time.now.to_i }
    Redis::Alfred.set(redis_key(source_id), payload.to_json, ex: TTL)
    failures
  end

  private

  def retry_delay(failures)
    RETRY_BACKOFF[failures - 1] || RETRY_BACKOFF.last
  end

  def read_state(source_id)
    raw = Redis::Alfred.get(redis_key(source_id))
    return {} if raw.blank?

    JSON.parse(raw)
  rescue JSON::ParserError
    {}
  end

  def redis_key(source_id)
    format(Redis::RedisKeys::IMAP_FAILED_MESSAGE, inbox_id: inbox.id, message_id_digest: Digest::SHA256.hexdigest(source_id))
  end
end
