class Whatsapp::HistorySync::ThreadImporter
  def initialize(sync)
    @sync = sync
    @inbox = sync.channel.inbox
  end

  def perform(source_id, messages)
    lock_key = format(::Redis::Alfred::WHATSAPP_MESSAGE_MUTEX, inbox_id: inbox.id, sender_id: source_id)
    result = nil
    acquired = Redis::LockManager.new.with_lock(lock_key, 30.seconds) do
      result = persist(source_id, messages)
    end
    raise "Could not lock WhatsApp history thread #{source_id}" unless acquired

    result
  end

  private

  attr_reader :sync, :inbox

  def persist(source_id, messages)
    conversation, conversation_created = Whatsapp::HistorySync::ContactConversationBuilder.new(sync, source_id).perform(messages)
    attributes = build_message_attributes(conversation, messages)
    return { messages: 0, conversation_created: conversation_created } if attributes.empty?

    result = Message.insert_all!(attributes, returning: %w[id]) # rubocop:disable Rails/SkipsModelValidations
    reindex_messages(result.rows.flatten)
    { messages: result.rows.size, conversation_created: conversation_created }
  end

  def build_message_attributes(conversation, messages)
    builder = Whatsapp::HistorySync::MessageBuilder.new(sync, conversation)
    messages.filter_map { |message| builder.perform(message) }
  end

  def reindex_messages(message_ids)
    Message.where(id: message_ids).find_each do |message|
      message.__send__(:reindex_for_search) if message.should_index?
    end
  end
end
