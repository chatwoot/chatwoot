# frozen_string_literal: true

module MyinvestChatImport
  class Importer
    SOURCE_PROVIDER = 'myinvest_history_v1'
    RECORD_TYPES = {
      'contact' => 'Contact',
      'conversation' => 'Conversation',
      'message' => 'Message'
    }.freeze

    def initialize(bundle:, adapter:, identity:)
      @bundle = bundle
      @adapter = adapter
      @identity = identity
      @stats = RECORD_TYPES.keys.to_h { |type| [type, { 'created' => 0, 'reused' => 0 }] }
      @import_id = nil
    end

    def call
      adapter.with_advisory_lock(identity.tenant_lock(bundle.tenant_key)) do
        begin
          account_id = adapter.resolve_account(bundle.tenant_key)
          inbox_id = adapter.ensure_history_inbox(account_id)
          @import_id = adapter.begin_import(
            account_id: account_id,
            export_id_hmac: identity.for(bundle, 'export', bundle.export_id),
            bundle_sha256: bundle.bundle_sha256,
            source_namespace_hmac: identity.for(bundle, 'namespace', bundle.source_namespace),
            schema_version: bundle.schema_version,
            total_records: bundle.total_records
          )
          import_contacts(account_id)
          import_conversations(account_id, inbox_id)
          adapter.complete_import(import_id: @import_id, processed_records: bundle.total_records, stats: @stats)
        rescue StandardError => error
          adapter.fail_import(import_id: @import_id, error_code: safe_error_code(error)) if @import_id
          raise
        end
      end
      @stats
    end

    private

    attr_reader :adapter, :bundle, :identity

    def import_contacts(account_id)
      bundle.contacts.each do |record|
        adapter.transaction do
          resolve_record(account_id, 'contact', record) do
            created_at = parse_time(record.fetch('created_at'))
            updated_at = parse_time(record.fetch('updated_at'))
            adapter.insert_contact(
              account_id: account_id,
              name: record.fetch('name'),
              email: record['email']&.downcase,
              phone_number: record['phone_number'],
              identifier: "history:#{identity.for(bundle, 'contact_identifier', record.fetch('external_id'))}",
              additional_attributes: provenance_attributes,
              custom_attributes: {},
              contact_type: 0,
              blocked: false,
              last_activity_at: updated_at,
              created_at: created_at,
              updated_at: updated_at
            )
          end
        end
      end
    end

    def import_conversations(account_id, inbox_id)
      messages_by_conversation = bundle.messages.group_by { |message| message.fetch('conversation_external_id') }

      bundle.conversations.each do |record|
        adapter.transaction do
          contact_id = mapped_record_id!(account_id, 'contact', record.fetch('contact_external_id'))
          contact_inbox = adapter.ensure_contact_inbox(
            contact_id: contact_id,
            inbox_id: inbox_id,
            source_id: "history:#{identity.for(bundle, 'contact_inbox', record.fetch('contact_external_id'))}",
            timestamp: parse_time(record.fetch('created_at'))
          )
          messages = messages_by_conversation.fetch(record.fetch('external_id'), [])
          conversation_id = resolve_record(account_id, 'conversation', record) do
            adapter.insert_conversation(conversation_attributes(account_id, inbox_id, contact_id, contact_inbox.fetch(:id), record, messages))
          end
          import_messages(account_id, inbox_id, conversation_id, messages)
        end
      end
    end

    def import_messages(account_id, inbox_id, conversation_id, records)
      pending = records.each_with_object([]) do |record, rows|
        mapping = mapping_for(account_id, 'message', record)
        if mapping
          increment('message', 'reused')
          next
        end

        rows << [record, message_attributes(account_id, inbox_id, conversation_id, record)]
      end
      return if pending.empty?

      ids = adapter.insert_messages(pending.map(&:last))
      raise LedgerIntegrityError unless ids.length == pending.length

      pending.zip(ids).each do |(record, _attributes), id|
        insert_mapping(account_id, 'message', record, id)
        increment('message', 'created')
      end
      adapter.insert_attachments(attachment_rows(account_id, pending, ids))
    end

    def attachment_rows(account_id, pending, message_ids)
      pending.zip(message_ids).flat_map do |(record, _attributes), message_id|
        record.fetch('attachments').map do |attachment|
          {
            account_id: account_id,
            message_id: message_id,
            path: bundle.attachment_path(attachment),
            filename: attachment.fetch('filename'),
            content_type: attachment.fetch('content_type'),
            byte_size: attachment.fetch('byte_size'),
            sha256: attachment.fetch('sha256'),
            storage_key: identity.for(bundle, 'attachment_storage', "#{record.fetch('external_id')}:#{attachment.fetch('external_id')}")
          }
        end
      end
    end

    def resolve_record(account_id, type, record)
      mapping = mapping_for(account_id, type, record)
      if mapping
        increment(type, 'reused')
        return mapping.fetch(:chatwoot_record_id)
      end

      id = yield
      insert_mapping(account_id, type, record, id)
      increment(type, 'created')
      id
    end

    def mapped_record_id!(account_id, type, external_id)
      source_object_id = identity.for(bundle, type, external_id)
      mapping = adapter.find_mapping(account_id: account_id, source_object_type: type, source_object_id: source_object_id)
      raise LedgerIntegrityError unless mapping

      mapping.fetch(:chatwoot_record_id)
    end

    def mapping_for(account_id, type, record)
      source_object_id = identity.for(bundle, type, record.fetch('external_id'))
      mapping = adapter.find_mapping(account_id: account_id, source_object_type: type, source_object_id: source_object_id)
      return nil unless mapping
      if type != 'contact' && mapping.fetch(:metadata).fetch('payload_sha256') != identity.payload(record)
        raise FingerprintConflictError
      end

      mapping
    end

    def insert_mapping(account_id, type, record, record_id)
      adapter.insert_mapping(
        account_id: account_id,
        data_import_id: @import_id,
        source_provider: SOURCE_PROVIDER,
        source_object_type: type,
        source_object_id: identity.for(bundle, type, record.fetch('external_id')),
        chatwoot_record_type: RECORD_TYPES.fetch(type),
        chatwoot_record_id: record_id,
        metadata: {
          'payload_sha256' => identity.payload(record),
          'source_namespace_hmac' => identity.for(bundle, 'namespace', bundle.source_namespace),
          'knowledge_import' => false
        }
      )
    end

    def conversation_attributes(account_id, inbox_id, contact_id, contact_inbox_id, record, messages)
      created_at = parse_time(record.fetch('created_at'))
      updated_at = parse_time(record.fetch('updated_at'))
      message_times = messages.map { |message| parse_time(message.fetch('created_at')) }
      last_activity_at = message_times.max || updated_at
      first_reply_at = messages.filter { |message| message.fetch('direction') == 'outgoing' }
                               .map { |message| parse_time(message.fetch('created_at')) }.min
      {
        account_id: account_id,
        inbox_id: inbox_id,
        status: 1,
        contact_id: contact_id,
        contact_inbox_id: contact_inbox_id,
        uuid: SecureRandom.uuid,
        identifier: "history:#{identity.for(bundle, 'conversation_identifier', record.fetch('external_id'))}",
        additional_attributes: provenance_attributes,
        custom_attributes: {},
        last_activity_at: last_activity_at,
        contact_last_seen_at: last_activity_at,
        agent_last_seen_at: last_activity_at,
        assignee_last_seen_at: last_activity_at,
        first_reply_created_at: first_reply_at,
        waiting_since: nil,
        created_at: created_at,
        updated_at: [updated_at, last_activity_at].max
      }
    end

    def message_attributes(account_id, inbox_id, conversation_id, record)
      direction = record.fetch('direction')
      created_at = parse_time(record.fetch('created_at'))
      updated_at = parse_time(record.fetch('updated_at'))
      {
        account_id: account_id,
        inbox_id: inbox_id,
        conversation_id: conversation_id,
        message_type: direction == 'incoming' ? 0 : 1,
        private: direction == 'note',
        status: 2,
        content_type: 0,
        content: record.fetch('content'),
        processed_message_content: record.fetch('content'),
        source_id: "history:#{identity.for(bundle, 'message_source', record.fetch('external_id'))}",
        sender_type: nil,
        sender_id: nil,
        content_attributes: {
          'external_created_at' => created_at.to_i,
          'myinvest_history_import' => true,
          'knowledge_import' => false
        },
        external_source_ids: {},
        additional_attributes: {
          'myinvest_history_import' => true,
          'knowledge_import' => false,
          'provenance' => record.fetch('metadata', {})
        },
        created_at: created_at,
        updated_at: updated_at
      }
    end

    def provenance_attributes
      {
        'myinvest_history_import' => true,
        'knowledge_import' => false,
        'tenant_key' => bundle.tenant_key,
        'source_namespace_hmac' => identity.for(bundle, 'namespace', bundle.source_namespace)
      }
    end

    def increment(type, state)
      @stats.fetch(type).fetch(state)
      @stats[type][state] += 1
    end

    def parse_time(value)
      Time.iso8601(value).utc
    end

    def safe_error_code(error)
      error.respond_to?(:code) ? error.code : 'internal_import_error'
    end
  end
end
