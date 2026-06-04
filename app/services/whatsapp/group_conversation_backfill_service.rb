class Whatsapp::GroupConversationBackfillService
  def initialize(batch_size: 100, inbox: nil)
    @batch_size = batch_size.to_i.positive? ? batch_size.to_i : 100
    @inbox = inbox
    @stats = { conversations: 0, members: 0 }
  end

  def perform
    scope.find_each(batch_size: @batch_size) do |conversation|
      backfill_conversation(conversation)
    end

    @stats
  end

  private

  def scope
    conversations = Conversation.joins(:contact_inbox)
                                .where(group: false)
                                .where('contact_inboxes.source_id LIKE ?', '%@g.us')
    conversations = conversations.where(inbox_id: @inbox.id) if @inbox.present?
    conversations
  end

  def backfill_conversation(conversation)
    existing_group_conversation = existing_group_conversation(conversation)
    if existing_group_conversation.present?
      Rails.logger.info(
        "[WHATSAPP][GROUP] skipping legacy duplicate conversation_id=#{conversation.id} existing_conversation_id=#{existing_group_conversation.id} " \
        "group_source_id=#{conversation.contact_inbox.source_id}"
      )
      backfill_members(existing_group_conversation, conversation.messages.includes(:sender))
      return
    end

    conversation.update!(
      group: true,
      group_source_id: conversation.contact_inbox.source_id,
      group_title: conversation.contact.name.presence || conversation.contact_inbox.source_id
    )
    @stats[:conversations] += 1

    backfill_members(conversation, conversation.messages.includes(:sender))
  end

  def backfill_members(conversation, messages)
    messages.find_each do |message|
      next unless message.sender.is_a?(Contact)
      next if message.sender_id == conversation.contact_id

      group_contact = conversation.group_contacts.find_or_create_by!(contact: message.sender)
      @stats[:members] += 1 if group_contact.previously_new_record?
    end
  end

  def existing_group_conversation(conversation)
    Conversation.where(inbox_id: conversation.inbox_id, group_source_id: conversation.contact_inbox.source_id)
                .where.not(id: conversation.id)
                .first
  end
end
