# frozen_string_literal: true

module MyinvestChatImport
  class HubspotExportVerifier
    SUPPORTED_EVENT_TYPES = HubspotExporter::SUPPORTED_MESSAGE_TYPES
    MESSAGE_EXTERNAL_PREFIX = 'hubspot-message:'
    THREAD_EXTERNAL_PREFIX = 'hubspot-thread:'
    ATTACHMENT_COMPARE_KEYS = %w[external_id path sha256 byte_size filename content_type].freeze

    def initialize(path)
      @path = path
    end

    def call
      bundle = Bundle.load(@path)
      raise ValidationError, 'unsupported_schema_version' unless bundle.schema_version == 2

      archive = bundle.load_archive_manifest!

      source_events = archive.fetch('source_events')
      selected_events = source_events.select { |event| SUPPORTED_EVENT_TYPES.include?(event['type']) }
      selected_ids = selected_events.map { |event| source_identity(event) }.sort
      message_ids = bundle.messages.map { |message| message_identity(message) }.sort
      raise ValidationError, 'source_event_subset_mismatch' unless selected_ids == message_ids
      raise ValidationError, 'source_event_subset_mismatch' unless selected_events.length == bundle.messages.length

      verify_thread_closure!(bundle, archive.fetch('source_threads'))
      verify_event_message_mapping!(bundle, selected_events)
      verify_no_urls!(source_events, archive.fetch('attachments'))
      verify_attachment_closure!(bundle, archive.fetch('attachments'), selected_events)

      {
        'event' => 'hubspot_history_export_verified',
        'tenant_key' => bundle.tenant_key,
        'schema_version' => bundle.schema_version,
        'knowledge_import' => false,
        'contacts' => bundle.contacts.length,
        'conversations' => bundle.conversations.length,
        'messages' => bundle.messages.length,
        'attachments' => bundle.messages.sum { |message| message.fetch('attachments').length },
        'archived_threads' => archive.fetch('source_threads').length,
        'archived_events' => source_events.length,
        'source_message_events' => selected_events.count { |event| event['type'] == 'MESSAGE' },
        'source_comment_events' => selected_events.count { |event| event['type'] == 'COMMENT' },
        'skipped_events' => source_events.length - selected_events.length,
        'source_subset_equal' => true,
        'attachment_archive_closed' => true,
        'import_files_digest_match' => true,
        'archive_files_digest_match' => true,
        'event_identity_match' => true,
        'content_mapping_match' => true,
        'attachment_closure_match' => true,
        'no_urls' => true
      }
    end

    private

    def source_identity(event)
      event.fetch('id')
    rescue KeyError
      raise ValidationError, 'archive_event_schema_mismatch'
    end

    def message_identity(message)
      external_id = message.fetch('external_id')
      raise ValidationError, 'source_event_subset_mismatch' unless external_id.start_with?(MESSAGE_EXTERNAL_PREFIX)

      external_id.delete_prefix(MESSAGE_EXTERNAL_PREFIX)
    end

    def conversation_identity(conversation)
      external_id = conversation.fetch('external_id')
      raise ValidationError, 'source_thread_conversation_mismatch' unless external_id.start_with?(THREAD_EXTERNAL_PREFIX)

      external_id.delete_prefix(THREAD_EXTERNAL_PREFIX)
    end

    def verify_thread_closure!(bundle, source_threads)
      thread_ids = source_threads.map { |thread| thread.fetch('id') }.sort
      conversation_ids = bundle.conversations.map { |conversation| conversation_identity(conversation) }.sort
      raise ValidationError, 'source_thread_conversation_mismatch' unless thread_ids == conversation_ids
    end

    def verify_event_message_mapping!(bundle, selected_events)
      events_by_id = selected_events.to_h { |event| [source_identity(event), event] }
      bundle.messages.each do |message|
        event = events_by_id.fetch(message_identity(message))
        expected_thread_id = conversation_identity(
          'external_id' => message.fetch('conversation_external_id')
        )
        raise ValidationError, 'source_event_thread_mismatch' unless event.fetch('archiveThreadId') == expected_thread_id
        raise ValidationError, 'source_event_direction_mismatch' unless message.fetch('direction') == event_direction(event)

        created_at, updated_at = ordered_timestamps(event.fetch('createdAt'), event['updatedAt'] || event.fetch('createdAt'))
        raise ValidationError, 'source_event_timestamp_mismatch' unless message.fetch('created_at') == created_at
        raise ValidationError, 'source_event_timestamp_mismatch' unless message.fetch('updated_at') == updated_at
        raise ValidationError, 'source_event_content_mismatch' unless message.fetch('content') == event_content(event)
      end
    rescue KeyError => e
      raise ValidationError, archive_event_missing_code(e.key)
    end

    def verify_no_urls!(source_events, archived_attachments)
      source_events.each do |event|
        Array(event['attachments']).each do |attachment|
          next unless attachment.is_a?(Hash) && attachment['type'] == 'FILE'

          raise ValidationError, 'url_in_source_archive' if attachment.key?('url')

          archived_file = attachment['archivedFile']
          raise ValidationError, 'url_in_source_archive' if archived_file.is_a?(Hash) && archived_file.key?('url')
        end
      end
      archived_attachments.each do |attachment|
        raise ValidationError, 'url_in_source_archive' if attachment.key?('url')
      end
    end

    def verify_attachment_closure!(bundle, archive_attachments, selected_events)
      message_attachments = bundle.messages.flat_map do |message|
        message.fetch('attachments').map do |attachment|
          attachment.merge('source_message_id' => message_identity(message))
        end
      end
      raise ValidationError, 'attachment_archive_not_closed' unless archive_attachments.length == message_attachments.length

      archive_by_identity = index_attachments!(archive_attachments)
      message_by_identity = index_attachments!(message_attachments)
      raise ValidationError, 'attachment_archive_not_closed' unless archive_by_identity.keys.sort == message_by_identity.keys.sort

      archive_by_identity.each do |identity, archived|
        expected = message_by_identity.fetch(identity)
        ATTACHMENT_COMPARE_KEYS.each do |key|
          raise ValidationError, 'attachment_archive_not_closed' unless archived.fetch(key) == expected.fetch(key)
        end
      end

      selected_events.each do |event|
        Array(event['attachments']).select { |attachment| attachment.is_a?(Hash) && attachment['type'] == 'FILE' }.each do |attachment|
          local = attachment['archivedFile']
          raise ValidationError, 'attachment_archive_not_closed' unless local.is_a?(Hash)
          raise ValidationError, 'attachment_archive_not_closed' if attachment.key?('url')

          identity = [source_identity(event), local.fetch('sha256')]

          raise ValidationError, 'attachment_archive_not_closed' unless archive_by_identity.key?(identity)
          ATTACHMENT_COMPARE_KEYS.each do |key|
            raise ValidationError, 'attachment_archive_not_closed' unless local.fetch(key) == archive_by_identity.fetch(identity).fetch(key)
          end
        end
      end
    rescue KeyError
      raise ValidationError, 'attachment_archive_not_closed'
    end

    def index_attachments!(rows)
      rows.each_with_object({}) do |attachment, index|
        identity = [attachment.fetch('source_message_id'), attachment.fetch('sha256')]
        raise ValidationError, 'attachment_archive_not_closed' if index.key?(identity)

        index[identity] = attachment
      end
    end

    def event_direction(event)
      return 'note' if event.fetch('type') == 'COMMENT'

      case event.fetch('direction')
      when 'INCOMING' then 'incoming'
      when 'OUTGOING' then 'outgoing'
      else raise ValidationError, 'unsupported_source_event_direction'
      end
    rescue KeyError => e
      raise ValidationError, archive_event_missing_code(e.key)
    end

    def archive_event_missing_code(key)
      case key
      when 'archiveThreadId' then 'archive_event_missing_archive_thread_id'
      when 'createdAt' then 'archive_event_missing_created_at'
      when 'direction' then 'archive_event_missing_direction'
      else 'archive_event_schema_mismatch'
      end
    end

    def event_content(event)
      text = event['text'].to_s
      text = strip_html(event['richText'].to_s) if text.strip.empty?
      text = '[Nachricht ohne Textinhalt]' if text.strip.empty?
      text[0, Bundle::MAX_MESSAGE_LENGTH]
    end

    def strip_html(value)
      CGI.unescapeHTML(value.gsub(/<br\s*\/?>/i, "\n").gsub(/<\/p>/i, "\n").gsub(/<[^>]+>/, ' '))
         .gsub(/[ \t]+/, ' ').gsub(/ *\n+ */, "\n").strip
    end

    def ordered_timestamps(created_value, updated_value)
      created_time = Time.iso8601(created_value.to_s).utc
      updated_time = Time.iso8601(updated_value.to_s).utc
      updated_time = created_time if updated_time < created_time
      [created_time.iso8601, updated_time.iso8601]
    rescue ArgumentError
      raise ValidationError, 'invalid_source_event_timestamp'
    end
  end
end
