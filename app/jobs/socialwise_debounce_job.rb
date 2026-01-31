# Job to process debounced messages for SocialWise Flow integration
# This job implements a "reset timer" debounce with max timeout:
# - Each new message resets the silence timer
# - Processing happens after X ms of silence OR after max timeout (whichever comes first)
class SocialwiseDebounceJob < ApplicationJob
  queue_as :medium

  def perform(conversation_id, hook_id, event_name, debounce_ms = 5000, max_timeout_ms = 30_000)
    Rails.logger.info "[SOCIALWISE-DEBOUNCE] Job triggered for conversation #{conversation_id}"

    conversation = Conversation.find_by(id: conversation_id)
    hook = Integrations::Hook.find_by(id: hook_id)

    unless conversation && hook
      Rails.logger.warn "[SOCIALWISE-DEBOUNCE] Conversation or hook not found: conversation=#{conversation_id}, hook=#{hook_id}"
      return
    end

    # Check if we should process now or skip
    unless should_process_now?(conversation_id, debounce_ms, max_timeout_ms)
      Rails.logger.info '[SOCIALWISE-DEBOUNCE] Not ready to process yet, skipping (another job will handle it)'
      return
    end

    # Acquire lock to prevent race conditions
    lock_key = format(Redis::Alfred::SOCIALWISE_DEBOUNCE_LOCK, conversation_id: conversation_id)
    unless acquire_lock(lock_key)
      Rails.logger.info "[SOCIALWISE-DEBOUNCE] Could not acquire lock for conversation #{conversation_id}, skipping"
      return
    end

    begin
      # Double-check after acquiring lock (another job might have processed)
      messages_key = format(Redis::Alfred::SOCIALWISE_DEBOUNCE_MESSAGES, conversation_id: conversation_id)
      if Redis::Alfred.lrange(messages_key, 0, -1).blank?
        Rails.logger.info '[SOCIALWISE-DEBOUNCE] Messages already processed by another job'
        return
      end

      process_debounced_messages(conversation, hook, event_name)
    ensure
      release_lock(lock_key)
    end
  end

  private

  # Determine if this job should process now based on silence time and max timeout
  def should_process_now?(conversation_id, debounce_ms, max_timeout_ms)
    current_time = Time.current.to_f
    debounce_seconds = debounce_ms / 1000.0
    max_timeout_seconds = max_timeout_ms / 1000.0

    first_at_key = format(Redis::Alfred::SOCIALWISE_DEBOUNCE_FIRST_AT, conversation_id: conversation_id)
    last_at_key = format(Redis::Alfred::SOCIALWISE_DEBOUNCE_LAST_AT, conversation_id: conversation_id)

    first_at = Redis::Alfred.get(first_at_key)&.to_f
    last_at = Redis::Alfred.get(last_at_key)&.to_f

    # If no timestamps, something went wrong - process anyway
    if first_at.nil? || last_at.nil?
      Rails.logger.warn '[SOCIALWISE-DEBOUNCE] Missing timestamps, processing anyway'
      return true
    end

    time_since_first = current_time - first_at
    time_since_last = current_time - last_at

    Rails.logger.info "[SOCIALWISE-DEBOUNCE] Time since first: #{time_since_first.round(2)}s, Time since last: #{time_since_last.round(2)}s"
    Rails.logger.info "[SOCIALWISE-DEBOUNCE] Required silence: #{debounce_seconds}s, Max timeout: #{max_timeout_seconds}s"

    # Check 1: Has max timeout been reached? Process immediately
    if time_since_first >= max_timeout_seconds
      Rails.logger.info "[SOCIALWISE-DEBOUNCE] MAX TIMEOUT reached (#{time_since_first.round(2)}s >= #{max_timeout_seconds}s) - processing now"
      return true
    end

    # Check 2: Has enough silence passed since last message?
    if time_since_last >= debounce_seconds
      Rails.logger.info "[SOCIALWISE-DEBOUNCE] SILENCE reached (#{time_since_last.round(2)}s >= #{debounce_seconds}s) - processing now"
      return true
    end

    # Not ready yet - a newer message reset the timer
    Rails.logger.info "[SOCIALWISE-DEBOUNCE] Not ready: silence=#{time_since_last.round(2)}s < #{debounce_seconds}s, timeout=#{time_since_first.round(2)}s < #{max_timeout_seconds}s"
    false
  end

  def process_debounced_messages(conversation, hook, event_name)
    messages_key = format(Redis::Alfred::SOCIALWISE_DEBOUNCE_MESSAGES, conversation_id: conversation.id)
    first_at_key = format(Redis::Alfred::SOCIALWISE_DEBOUNCE_FIRST_AT, conversation_id: conversation.id)
    last_at_key = format(Redis::Alfred::SOCIALWISE_DEBOUNCE_LAST_AT, conversation_id: conversation.id)

    # Get all pending messages
    pending_messages_json = Redis::Alfred.lrange(messages_key, 0, -1)

    if pending_messages_json.blank?
      Rails.logger.info "[SOCIALWISE-DEBOUNCE] No pending messages for conversation #{conversation.id}"
      return
    end

    # Parse and sort messages by timestamp
    pending_messages = pending_messages_json.map { |json| JSON.parse(json) }
    pending_messages.sort_by! { |m| m['timestamp'] }

    Rails.logger.info "[SOCIALWISE-DEBOUNCE] Found #{pending_messages.count} pending messages for conversation #{conversation.id}"

    # Clear all debounce data from Redis
    Redis::Alfred.delete(messages_key)
    Redis::Alfred.delete(first_at_key)
    Redis::Alfred.delete(last_at_key)

    # Get the last message to use as reference for the response
    last_message_id = pending_messages.last['message_id']
    last_message = Message.find_by(id: last_message_id)

    unless last_message
      Rails.logger.warn "[SOCIALWISE-DEBOUNCE] Last message not found: #{last_message_id}"
      return
    end

    # Concatenate all message contents
    concatenated_content = pending_messages.filter_map { |m| m['content'] }.join("\n")

    Rails.logger.info "[SOCIALWISE-DEBOUNCE] Concatenated #{pending_messages.count} messages for conversation #{conversation.id}"
    Rails.logger.info "[SOCIALWISE-DEBOUNCE] Content: #{concatenated_content.truncate(200)}"

    # Build event_data with concatenated content
    event_data = {
      message: last_message,
      conversation: conversation,
      contact: conversation.contact,
      inbox: conversation.inbox
    }

    # Process with the SocialWise Flow processor using concatenated content
    processor = Integrations::SocialwiseFlow::DebounceProcessorService.new(
      event_name: event_name,
      hook: hook,
      event_data: event_data,
      concatenated_content: concatenated_content
    )
    processor.perform

    Rails.logger.info "[SOCIALWISE-DEBOUNCE] Processing completed for conversation #{conversation.id}"
  end

  def acquire_lock(key)
    # Try to acquire lock with 30 second expiry
    Redis::Alfred.set(key, '1', nx: true, ex: 30)
  end

  def release_lock(key)
    Redis::Alfred.delete(key)
  end
end
