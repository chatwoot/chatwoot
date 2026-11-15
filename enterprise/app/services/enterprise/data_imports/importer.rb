module Enterprise::DataImports::Importer
  private

  def insert_messages(entries, attributes_by_source_id)
    messages = super
    request_imported_monitor_evaluations(entries.zip(messages).filter_map { |entry, message| message unless entry.message })
    messages
  end

  def create_message(conversation, contact, entry)
    message = super
    request_imported_monitor_evaluations([message]) if entry.message.nil? && message.is_a?(Message)
    message
  end

  def request_imported_monitor_evaluations(messages)
    public_messages = messages.select { |message| !message.private? && message.message_type.in?(%w[incoming outgoing]) }
    return if public_messages.empty?

    conversation = public_messages.first.conversation
    activity_times = public_messages.map(&:created_at)
    work = monitors_for_import(conversation, activity_times).filter_map do |monitor|
      ConversationMonitors::Scheduler.request_for_monitor(conversation, monitor, monitor.collection_version)
    end
    ConversationMonitors::Scheduler.wake(conversation.id) if work.present?
  end

  def monitors_for_import(conversation, activity_times)
    conversation.account.conversation_monitors.active.includes(:scans).select do |monitor|
      monitor.eligible_imported_activity?(conversation, activity_times)
    end
  end
end
