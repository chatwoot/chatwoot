class Whatsapp::HistorySync::ContactConversationBuilder
  HISTORY_SOURCE = 'whatsapp_history_sync'.freeze

  def initialize(sync, source_id)
    @sync = sync
    @inbox = sync.channel.inbox
    @source_id = source_id.to_s
  end

  def perform(messages)
    contact_inbox = find_or_create_contact_inbox
    find_or_create_conversation(contact_inbox, messages)
  end

  private

  attr_reader :sync, :inbox, :source_id

  def find_or_create_contact_inbox
    existing = inbox.contact_inboxes.find_by(source_id: normalized_source_id)
    return existing if existing

    Contact.transaction(requires_new: true) do
      contact = find_or_create_contact
      result = ContactInbox.insert_all!([contact_inbox_attributes(contact)], returning: %w[id]) # rubocop:disable Rails/SkipsModelValidations
      ContactInbox.find(result.rows.first.first)
    end
  rescue ActiveRecord::RecordNotUnique
    inbox.contact_inboxes.find_by!(source_id: normalized_source_id)
  end

  def contact_inbox_attributes(contact)
    {
      contact_id: contact.id,
      inbox_id: inbox.id,
      source_id: normalized_source_id,
      created_at: Time.current,
      updated_at: Time.current
    }
  end

  def find_or_create_contact
    contact = inbox.account.contacts.find_by(phone_number: phone_number) if phone_number
    return contact if contact

    result = Contact.insert_all!([contact_attributes], returning: %w[id]) # rubocop:disable Rails/SkipsModelValidations
    Contact.find(result.rows.first.first)
  end

  def contact_attributes
    {
      account_id: inbox.account_id,
      name: phone_number || source_id,
      phone_number: phone_number,
      contact_type: Contact.contact_types[:lead],
      additional_attributes: { source: HISTORY_SOURCE },
      created_at: Time.current,
      updated_at: Time.current
    }
  end

  def find_or_create_conversation(contact_inbox, messages)
    existing = inbox.account.conversations.find_by(identifier: history_conversation_identifier(contact_inbox))
    return [existing, false] if existing

    result = Conversation.insert_all!([conversation_attributes(contact_inbox, messages)], returning: %w[id]) # rubocop:disable Rails/SkipsModelValidations
    [Conversation.find(result.rows.first.first), true]
  end

  def conversation_attributes(contact_inbox, messages)
    timestamps = messages.map { |message| message_timestamp(message) }
    {
      account_id: inbox.account_id,
      inbox_id: inbox.id,
      contact_id: contact_inbox.contact_id,
      contact_inbox_id: contact_inbox.id,
      status: Conversation.statuses[:resolved],
      identifier: history_conversation_identifier(contact_inbox),
      additional_attributes: { source: HISTORY_SOURCE },
      created_at: timestamps.min,
      updated_at: timestamps.max,
      last_activity_at: timestamps.max,
      agent_last_seen_at: timestamps.max,
      assignee_last_seen_at: timestamps.max
    }
  end

  def normalized_source_id
    @normalized_source_id ||= Whatsapp::PhoneNumberNormalizationService.new(inbox).normalize_and_find_contact_by_provider(source_id, :cloud)
  end

  def history_conversation_identifier(contact_inbox)
    "#{HISTORY_SOURCE}:#{inbox.id}:#{contact_inbox.source_id}"
  end

  def phone_number
    @phone_number ||= source_id.match?(/\A\d{1,15}\z/) ? "+#{source_id}" : nil
  end

  def message_timestamp(message)
    Time.zone.at(Integer(message.fetch('timestamp')))
  end
end
