class ConversationMonitors::Scheduler
  def self.request(conversation, invalidate: false, activity_at: Time.current, full_history: false)
    # Record work even while disabled if monitors exist: reenabling must catch up.
    account = conversation.account
    return unless account # Async cleanup can destroy an account before its messages.

    monitors = invalidate ? account.conversation_monitors.visible : account.conversation_monitors.active
    return unless monitors.exists?

    item = ConversationMonitors::WorkItem.for_conversation(conversation)
    item.request!(invalidate: invalidate, activity_at: activity_at, full_history: full_history)
    item
  end

  def self.request_for_monitor(conversation, monitor, version)
    item = ConversationMonitors::WorkItem.for_conversation(conversation)
    item.with_lock do
      monitor.with_lock do
        # Persist eligible imports while disabled; the evaluator enforces feature availability.
        return unless monitor.paused_at.nil? && monitor.deleted_at.nil? && monitor.collection_version == version

        evaluation = monitor.evaluations.find_or_initialize_by(conversation_id: conversation.id, account_id: conversation.account_id)
        return item if evaluation.status == 'matched'

        evaluation.update!(status: 'pending', requested_version: version, error_code: nil)
        item.request!(full_history: true)
      end
    end
    item
  end

  def self.wake(conversation_id)
    enqueue { ConversationMonitors::ProcessJob.set(wait: 3.seconds).perform_later(conversation_id) }
  end

  def self.start_scan(scan_id)
    enqueue { ConversationMonitors::ScanJob.perform_later(scan_id) }
  end

  def self.start_recheck(monitor_id, requested_at)
    enqueue { ConversationMonitors::RetryJob.perform_later(monitor_id, requested_at) }
  end

  def self.enqueue
    yield
  rescue StandardError => e
    # The committed database marker is recovered by DispatchJob if Redis is unavailable.
    Rails.logger.error("Conversation monitor enqueue failed: #{e.class.name}")
  end
  private_class_method :enqueue
end
