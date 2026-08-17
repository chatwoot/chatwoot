# frozen_string_literal: true

module MyinvestChatImport
  class RailsAdapter
    SOURCE_PROVIDER = Importer::SOURCE_PROVIDER
    HISTORY_INBOX_NAME = 'History Import'

    def with_advisory_lock(lock_key)
      lock_id = lock_key[0, 16].to_i(16)
      lock_id -= (1 << 64) if lock_id >= (1 << 63)
      connection.execute("SELECT pg_advisory_lock(#{connection.quote(lock_id)})")
      yield
    ensure
      connection.execute("SELECT pg_advisory_unlock(#{connection.quote(lock_id)})") if lock_id
    end

    def transaction(&block)
      ApplicationRecord.transaction(requires_new: true, &block)
    end

    def resolve_account(tenant_key)
      accounts = Account.where("custom_attributes ->> 'myinvest_tenant_key' = ?", tenant_key).limit(2).to_a
      raise TenantResolutionError unless accounts.one?

      accounts.first.id
    end

    def ensure_history_inbox(account_id)
      inboxes = Inbox.where(account_id: account_id, name: HISTORY_INBOX_NAME).limit(2).to_a
      raise UnsafeInboxError if inboxes.many?

      inbox = inboxes.first || insert_history_inbox(account_id)
      assert_bot_free!(inbox)
      inbox.id
    end

    def begin_import(account_id:, export_id_hmac:, bundle_sha256:, total_records:, source_namespace_hmac:, schema_version:)
      relation = DataImport.where(account_id: account_id, source_provider: SOURCE_PROVIDER)
                           .where("source_metadata ->> 'export_id_hmac' = ?", export_id_hmac)
      existing_imports = relation.limit(2).to_a
      raise LedgerIntegrityError if existing_imports.many?

      existing = existing_imports.first
      if existing
        raise FingerprintConflictError unless existing.source_metadata.fetch('bundle_sha256') == bundle_sha256

        relation.update_all(
          status: DataImport.statuses.fetch('processing'),
          source_metadata: existing.source_metadata.merge('schema_version' => schema_version),
          started_at: Time.current,
          completed_at: nil,
          processing_errors: nil,
          last_error_at: nil,
          updated_at: Time.current
        )
        return existing.id
      end

      now = Time.current
      attributes = {
        account_id: account_id,
        data_type: 'intercom',
        status: DataImport.statuses.fetch('processing'),
        total_records: total_records,
        processed_records: 0,
        name: "History Import v#{schema_version}",
        source_type: 'history',
        source_provider: SOURCE_PROVIDER,
        import_types: %w[contacts conversations],
        source_metadata: {
          'schema_version' => schema_version,
          'export_id_hmac' => export_id_hmac,
          'bundle_sha256' => bundle_sha256,
          'source_namespace_hmac' => source_namespace_hmac,
          'knowledge_import' => false
        },
        stats: {},
        cursor: {},
        started_at: now,
        created_at: now,
        updated_at: now
      }
      inserted_id(DataImport.insert_all!([attributes], returning: ['id']))
    end

    def find_mapping(account_id:, source_object_type:, source_object_id:)
      mapping = DataImportMapping.find_by(
        account_id: account_id,
        source_provider: SOURCE_PROVIDER,
        source_object_type: source_object_type,
        source_object_id: source_object_id
      )
      return nil unless mapping
      raise LedgerIntegrityError unless mapped_record_exists?(mapping.chatwoot_record_type, mapping.chatwoot_record_id, account_id)

      { chatwoot_record_id: mapping.chatwoot_record_id, metadata: mapping.metadata }
    end

    def insert_mapping(attributes)
      now = Time.current
      DataImportMapping.insert_all!([attributes.merge(created_at: now, updated_at: now)])
    end

    def insert_contact(attributes)
      inserted_id(Contact.insert_all!([attributes], returning: ['id']))
    end

    def ensure_contact_inbox(contact_id:, inbox_id:, source_id:, timestamp:)
      existing = ContactInbox.find_by(inbox_id: inbox_id, source_id: source_id)
      if existing
        raise LedgerIntegrityError unless existing.contact_id == contact_id

        return { id: existing.id }
      end

      attributes = {
        contact_id: contact_id,
        inbox_id: inbox_id,
        source_id: source_id,
        hmac_verified: true,
        created_at: timestamp,
        updated_at: timestamp
      }
      { id: inserted_id(ContactInbox.insert_all!([attributes], returning: ['id'])) }
    end

    def insert_conversation(attributes)
      inserted_id(Conversation.insert_all!([attributes], returning: ['id']))
    end

    def insert_messages(rows)
      return [] if rows.empty?

      Message.insert_all!(rows, returning: ['id']).rows.flatten
    end

    def insert_attachments(rows)
      return if rows.empty?

      uploaded_keys = []
      rows.each do |row|
        checksum = Base64.strict_encode64(Digest::MD5.file(row.fetch(:path)).digest)
        key = "myinvest-history/#{row.fetch(:storage_key)}"
        uploaded_keys << key
        File.open(row.fetch(:path), 'rb') do |file|
          ActiveStorage::Blob.service.upload(key, file, checksum: checksum)
        end
        now = Time.current
        blob_id = inserted_id(
          ActiveStorage::Blob.insert_all!([{
            key: key,
            filename: row.fetch(:filename),
            content_type: row.fetch(:content_type),
            metadata: { 'identified' => true, 'analyzed' => false },
            byte_size: row.fetch(:byte_size),
            checksum: checksum,
            service_name: ActiveStorage::Blob.service.name,
            created_at: now
          }], returning: ['id'])
        )
        attachment_id = inserted_id(
          Attachment.insert_all!([{
            account_id: row.fetch(:account_id),
            message_id: row.fetch(:message_id),
            file_type: attachment_file_type(row.fetch(:content_type)),
            extension: File.extname(row.fetch(:filename)).delete_prefix('.').presence,
            meta: { 'myinvest_history_import' => true, 'knowledge_import' => false, 'sha256' => row.fetch(:sha256) },
            created_at: now,
            updated_at: now
          }], returning: ['id'])
        )
        ActiveStorage::Attachment.insert_all!([{
          name: 'file',
          record_type: 'Attachment',
          record_id: attachment_id,
          blob_id: blob_id,
          created_at: now
        }])
      end
    rescue StandardError
      uploaded_keys.each { |key| ActiveStorage::Blob.service.delete(key) }
      raise
    end

    def complete_import(import_id:, processed_records:, stats:)
      DataImport.where(id: import_id).update_all(
        status: DataImport.statuses.fetch('completed'),
        processed_records: processed_records,
        stats: stats,
        processing_errors: nil,
        last_error_at: nil,
        completed_at: Time.current,
        updated_at: Time.current
      )
    end

    def fail_import(import_id:, error_code:)
      DataImport.where(id: import_id).update_all(
        status: DataImport.statuses.fetch('failed'),
        processing_errors: error_code,
        last_error_at: Time.current,
        updated_at: Time.current
      )
    end

    private

    def connection
      ApplicationRecord.connection
    end

    def inserted_id(result)
      id = result.rows.dig(0, 0)
      raise LedgerIntegrityError unless id

      id
    end

    def attachment_file_type(content_type)
      return Attachment.file_types.fetch('image') if content_type.start_with?('image/')
      return Attachment.file_types.fetch('audio') if content_type.start_with?('audio/')
      return Attachment.file_types.fetch('video') if content_type.start_with?('video/')

      Attachment.file_types.fetch('file')
    end

    def insert_history_inbox(account_id)
      now = Time.current
      channel_id = inserted_id(
        Channel::Api.insert_all!([{
          account_id: account_id,
          webhook_url: nil,
          identifier: SecureRandom.hex(32),
          hmac_token: SecureRandom.hex(32),
          additional_attributes: { 'myinvest_history_import' => true, 'knowledge_import' => false },
          created_at: now,
          updated_at: now
        }], returning: ['id'])
      )
      inbox_id = inserted_id(
        Inbox.insert_all!([{
          account_id: account_id,
          channel_id: channel_id,
          channel_type: 'Channel::Api',
          name: HISTORY_INBOX_NAME,
          enable_auto_assignment: false,
          greeting_enabled: false,
          working_hours_enabled: false,
          csat_survey_enabled: false,
          allow_messages_after_resolved: false,
          lock_to_single_conversation: false,
          created_at: now,
          updated_at: now
        }], returning: ['id'])
      )
      Inbox.find(inbox_id)
    end

    def assert_bot_free!(inbox)
      unsafe = inbox.channel_type != 'Channel::Api' || inbox.channel.webhook_url.present? ||
               AgentBotInbox.where(inbox_id: inbox.id).exists? ||
               Integrations::Hook.where(inbox_id: inbox.id, status: Integrations::Hook.statuses.fetch('enabled')).exists? ||
               Webhook.where(inbox_id: inbox.id).exists?
      raise UnsafeInboxError if unsafe
    end

    def mapped_record_exists?(record_type, record_id, account_id)
      model = { 'Contact' => Contact, 'Conversation' => Conversation, 'Message' => Message }[record_type]
      model&.where(id: record_id, account_id: account_id)&.exists? == true
    end
  end
end
