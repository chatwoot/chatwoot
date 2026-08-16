# frozen_string_literal: true

require_relative '../lib/myinvest_chat_import'
require_relative '../lib/myinvest_chat_import/rails_adapter'

bundle_path = ARGV.fetch(0) { ENV.fetch('CHAT_IMPORT_BUNDLE_PATH') }
bundle = MyinvestChatImport::Bundle.load(bundle_path)
identity = MyinvestChatImport::Identity.new(ENV.fetch('CHAT_IMPORT_HMAC_KEY'))
account = Account.where("custom_attributes ->> 'myinvest_tenant_key' = ?", bundle.tenant_key).sole
inbox = account.inboxes.where(name: MyinvestChatImport::RailsAdapter::HISTORY_INBOX_NAME, channel_type: 'Channel::Api').sole

unsafe_inbox = inbox.channel.webhook_url.present? ||
               AgentBotInbox.where(inbox_id: inbox.id).exists? ||
               Integrations::Hook.where(inbox_id: inbox.id, status: Integrations::Hook.statuses.fetch('enabled')).exists? ||
               Webhook.where(inbox_id: inbox.id).exists?
raise MyinvestChatImport::UnsafeInboxError if unsafe_inbox

records = {
  'contact' => bundle.contacts,
  'conversation' => bundle.conversations,
  'message' => bundle.messages
}
mappings = records.to_h do |type, source_records|
  mapped = source_records.to_h do |record|
    source_object_id = identity.for(bundle, type, record.fetch('external_id'))
    mapping = DataImportMapping.find_by!(
      account_id: account.id,
      source_provider: MyinvestChatImport::Importer::SOURCE_PROVIDER,
      source_object_type: type,
      source_object_id: source_object_id
    )
    raise MyinvestChatImport::FingerprintConflictError unless mapping.metadata.fetch('payload_sha256') == identity.payload(record)
    raise MyinvestChatImport::KnowledgeSeparationError unless mapping.metadata.fetch('knowledge_import') == false

    [record.fetch('external_id'), mapping]
  end
  [type, mapped]
end

contacts = Contact.where(id: mappings.fetch('contact').values.map(&:chatwoot_record_id)).to_a
conversations = Conversation.where(id: mappings.fetch('conversation').values.map(&:chatwoot_record_id)).to_a
messages = Message.where(id: mappings.fetch('message').values.map(&:chatwoot_record_id)).to_a
contacts_by_id = contacts.index_by(&:id)
conversations_by_id = conversations.index_by(&:id)
messages_by_id = messages.index_by(&:id)

raise MyinvestChatImport::LedgerIntegrityError unless contacts.length == bundle.contacts.length
raise MyinvestChatImport::LedgerIntegrityError unless conversations.length == bundle.conversations.length
raise MyinvestChatImport::LedgerIntegrityError unless messages.length == bundle.messages.length
raise MyinvestChatImport::KnowledgeSeparationError unless contacts.all? do |contact|
  contact.account_id == account.id && contact.additional_attributes.fetch('knowledge_import') == false
end
raise MyinvestChatImport::KnowledgeSeparationError unless conversations.all? do |conversation|
  conversation.account_id == account.id && conversation.inbox_id == inbox.id && conversation.resolved? &&
    conversation.additional_attributes.fetch('knowledge_import') == false
end
raise MyinvestChatImport::KnowledgeSeparationError unless messages.all? do |message|
  message.account_id == account.id && message.inbox_id == inbox.id &&
    message.additional_attributes.fetch('knowledge_import') == false
end

bundle.contacts.each do |record|
  contact = contacts_by_id.fetch(mappings.fetch('contact').fetch(record.fetch('external_id')).chatwoot_record_id)
  raise MyinvestChatImport::LedgerIntegrityError unless contact.name == record.fetch('name') &&
                                                         contact.created_at == Time.iso8601(record.fetch('created_at'))
end
bundle.conversations.each do |record|
  conversation = conversations_by_id.fetch(mappings.fetch('conversation').fetch(record.fetch('external_id')).chatwoot_record_id)
  contact_id = mappings.fetch('contact').fetch(record.fetch('contact_external_id')).chatwoot_record_id
  raise MyinvestChatImport::LedgerIntegrityError unless conversation.contact_id == contact_id &&
                                                         conversation.created_at == Time.iso8601(record.fetch('created_at'))
end
bundle.messages.each do |record|
  message = messages_by_id.fetch(mappings.fetch('message').fetch(record.fetch('external_id')).chatwoot_record_id)
  conversation_id = mappings.fetch('conversation').fetch(record.fetch('conversation_external_id')).chatwoot_record_id
  expected_type = record.fetch('direction') == 'incoming' ? 'incoming' : 'outgoing'
  expected_private = record.fetch('direction') == 'note'
  raise MyinvestChatImport::LedgerIntegrityError unless message.conversation_id == conversation_id &&
                                                         message.message_type == expected_type &&
                                                         message.private == expected_private &&
                                                         message.content == record.fetch('content') &&
                                                         message.created_at == Time.iso8601(record.fetch('created_at'))
end

export_id_hmac = identity.for(bundle, 'export', bundle.export_id)
data_import = DataImport.where(account_id: account.id, source_provider: MyinvestChatImport::Importer::SOURCE_PROVIDER)
                        .where("source_metadata ->> 'export_id_hmac' = ?", export_id_hmac).sole
raise MyinvestChatImport::LedgerIntegrityError unless data_import.completed? && data_import.processed_records == bundle.total_records
raise MyinvestChatImport::KnowledgeSeparationError unless data_import.source_metadata.fetch('knowledge_import') == false

puts JSON.generate(
  event: 'history_import_verified',
  tenant_key: bundle.tenant_key,
  contacts: contacts.length,
  conversations: conversations.length,
  messages: messages.length,
  source_timestamps_preserved: true,
  directions_preserved: true,
  knowledge_import: false,
  inbox_safe: true
)
