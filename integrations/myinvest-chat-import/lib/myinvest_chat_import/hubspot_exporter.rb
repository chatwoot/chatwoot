# frozen_string_literal: true

module MyinvestChatImport
  class HubspotExporter
    SOURCE_NAMESPACE = 'hubspot-conversations-v3'
    SUPPORTED_MESSAGE_TYPES = %w[MESSAGE COMMENT].freeze

    def initialize(client:, output_path:, tenant_key:, inbox_ids:, channel_account_ids:, export_id:, created_at: Time.now.utc)
      @client = client
      @output_path = File.expand_path(output_path.to_s)
      @tenant_key = tenant_key.to_s
      @inbox_ids = Array(inbox_ids).map(&:to_s).uniq.freeze
      @channel_account_ids = Array(channel_account_ids).map(&:to_s).uniq.freeze
      @export_id = export_id.to_s
      @created_at = created_at.utc
      validate_configuration!
    end

    def call
      prepare_output!
      threads = selected_threads
      messages_by_thread, events_by_thread, skipped_events = selected_messages(threads)
      attachments_by_message, attachment_archive = archive_attachments(events_by_thread)
      contact_records = build_contacts(threads)
      conversation_records = build_conversations(threads)
      message_records = build_messages(threads, messages_by_thread, attachments_by_message)
      write_bundle(contact_records, conversation_records, message_records)
      write_source_archive(threads, events_by_thread, attachment_archive)

      {
        contacts: contact_records.length,
        conversations: conversation_records.length,
        messages: message_records.length,
        attachments: attachment_archive.length,
        archived_events: events_by_thread.values.sum(&:length),
        skipped_events: skipped_events
      }
    rescue StandardError
      FileUtils.remove_entry_secure(output_path) if File.directory?(output_path)
      raise
    end

    private

    attr_reader :channel_account_ids, :client, :created_at, :export_id, :inbox_ids, :output_path, :tenant_key

    def validate_configuration!
      raise ArgumentError, 'unsupported tenant' unless Bundle::TENANTS.include?(tenant_key)
      raise ArgumentError, 'inbox ids are required' if inbox_ids.empty? || inbox_ids.any?(&:empty?)
      raise ArgumentError, 'channel account ids are required' if channel_account_ids.empty? || channel_account_ids.any?(&:empty?)
      raise ArgumentError, 'export id is required' if export_id.empty?
      raise ArgumentError, 'output path already exists' if File.exist?(output_path) || File.symlink?(output_path)
    end

    def selected_threads
      rows = inbox_ids.flat_map { |inbox_id| client.threads(inbox_id).to_a }
      rows.select { |thread| channel_account_ids.include?(thread.fetch('originalChannelAccountId').to_s) }
          .uniq { |thread| thread.fetch('id').to_s }
          .sort_by { |thread| thread.fetch('id').to_s }
    end

    def selected_messages(threads)
      skipped_events = 0
      events_by_thread = {}
      by_thread = threads.to_h do |thread|
        thread_id = thread.fetch('id').to_s
        events = client.messages(thread_id, archived: thread['archived'] == true).map do |message|
          hydrate_original_content(thread_id, message)
        end
        events_by_thread[thread_id] = events
        selected = events.each_with_object([]) do |message, rows|
          unless SUPPORTED_MESSAGE_TYPES.include?(message['type'])
            skipped_events += 1
            next
          end

          rows << message
        end
        [thread_id, selected.sort_by { |message| [timestamp(message, 'createdAt'), message.fetch('id').to_s] }]
      end
      [by_thread, events_by_thread, skipped_events]
    end

    def hydrate_original_content(thread_id, message)
      return message unless message['type'] == 'MESSAGE'
      return message if message['truncationStatus'].to_s.empty? || message['truncationStatus'] == 'NOT_TRUNCATED'

      original = client.original_content(thread_id, message.fetch('id').to_s)
      message.merge('text' => original['text'].to_s, 'richText' => original['richText'].to_s,
                    'archiveOriginalContentFetched' => true)
    end

    def archive_attachments(events_by_thread)
      by_file_id = {}
      by_message = {}
      archive = []
      events_by_thread.each_value do |events|
        events.each do |message|
          descriptors = Array(message['attachments']).each_with_object([]) do |attachment, selected|
            next unless attachment['type'] == 'FILE'

            file_id = attachment.fetch('fileId').to_s
            descriptor = by_file_id[file_id] ||= download_attachment(file_id, attachment)
            archive << descriptor.merge('source_message_id' => message.fetch('id').to_s)
            selected << descriptor
          end
          by_message[message.fetch('id').to_s] = descriptors.uniq { |descriptor| descriptor.fetch('external_id') }
        end
      end
      [by_message, archive]
    end

    def download_attachment(file_id, attachment)
      raise ArgumentError, 'HubSpot file id must be numeric' unless file_id.match?(/\A\d+\z/)

      temporary_path = File.join(output_path, 'attachments', ".download-#{file_id}")
      metadata = client.download_file(file_id, temporary_path)
      digest = Digest::SHA256.file(temporary_path).hexdigest
      relative_path = "attachments/#{digest}"
      final_path = File.join(output_path, relative_path)
      if File.exist?(final_path)
        raise ArgumentError, 'attachment digest collision' unless File.file?(final_path) && Digest::SHA256.file(final_path).hexdigest == digest

        File.delete(temporary_path)
      else
        File.rename(temporary_path, final_path)
        File.chmod(0o600, final_path)
      end
      filename = safe_filename(metadata['filename'].to_s.empty? ? attachment['name'] : metadata['filename'], file_id)
      content_type = metadata.fetch('content_type').to_s
      content_type = 'application/octet-stream' unless content_type.match?(%r{\A[a-z0-9][a-z0-9.+-]*/[a-z0-9][a-z0-9.+-]*\z}i)
      {
        'external_id' => "hubspot-file:#{file_id}",
        'path' => relative_path,
        'sha256' => digest,
        'byte_size' => Integer(metadata.fetch('byte_size')),
        'filename' => filename,
        'content_type' => content_type
      }
    ensure
      File.delete(temporary_path) if temporary_path && File.file?(temporary_path)
    end

    def safe_filename(value, file_id)
      filename = File.basename(value.to_s.tr('\\', '/')).delete("\0\r\n").strip
      filename = "hubspot-file-#{file_id}" if filename.empty? || filename == '.' || filename == '..'
      filename[0, 255]
    end

    def build_contacts(threads)
      contact_ids = threads.map { |thread| thread['associatedContactId']&.to_s }.compact.reject(&:empty?).uniq.sort
      contacts = client.contacts(contact_ids)
      contact_keys = threads.map { |thread| contact_key(thread) }.uniq.sort
      first_seen = threads.group_by { |thread| contact_key(thread) }

      contact_keys.map do |contact_id|
        contact = contacts.fetch(contact_id, { 'id' => contact_id, 'properties' => {} })
        properties = contact.fetch('properties', {})
        thread_times = first_seen.fetch(contact_id).flat_map do |thread|
          [thread['createdAt'], thread['closedAt'], thread['latestMessageTimestamp']].compact
        end
        fallback_created_at = thread_times.min || created_at.iso8601
        fallback_updated_at = thread_times.max || fallback_created_at
        created_value = properties['createdate'] || fallback_created_at
        updated_value = properties['lastmodifieddate'] || fallback_updated_at
        created_value, updated_value = ordered_timestamps(created_value, updated_value)
        first_name = properties['firstname'].to_s.strip
        last_name = properties['lastname'].to_s.strip
        name = [first_name, last_name].reject(&:empty?).join(' ')
        name = "HubSpot Kontakt #{contact_id[-8, 8]}" if name.empty?
        email = properties['email'].to_s.strip.downcase
        phone = normalize_phone(properties['mobilephone']) || normalize_phone(properties['phone'])

        {
          'external_id' => contact_external_id(contact_id),
          'name' => name[0, 255],
          'email' => email.empty? ? nil : email,
          'phone_number' => phone,
          'created_at' => created_value,
          'updated_at' => updated_value
        }.compact
      end
    end

    def build_conversations(threads)
      threads.map do |thread|
        contact_id = contact_key(thread)

        created_value = thread.fetch('createdAt')
        updated_value = thread['closedAt'] || thread['latestMessageTimestamp'] || created_value
        created_value, updated_value = ordered_timestamps(created_value, updated_value)
        {
          'external_id' => conversation_external_id(thread.fetch('id')),
          'contact_external_id' => contact_external_id(contact_id),
          'status' => 'resolved',
          'created_at' => created_value,
          'updated_at' => updated_value
        }
      end
    end

    def build_messages(threads, messages_by_thread, attachments_by_message)
      threads.flat_map do |thread|
        messages_by_thread.fetch(thread.fetch('id').to_s).map do |message|
          created_value = message.fetch('createdAt')
          updated_value = message['updatedAt'] || created_value
          created_value, updated_value = ordered_timestamps(created_value, updated_value)
          attachment_types = Array(message['attachments']).map { |attachment| attachment['type'].to_s }.reject(&:empty?).uniq.sort
          metadata = {
            'source' => 'hubspot',
            'hubspot_channel_id' => thread.fetch('originalChannelId').to_s
          }
          metadata['hubspot_attachment_types'] = attachment_types unless attachment_types.empty?

          {
            'external_id' => "hubspot-message:#{message.fetch('id')}",
            'conversation_external_id' => conversation_external_id(thread.fetch('id')),
            'direction' => message_direction(message),
            'content' => message_content(message),
            'created_at' => created_value,
            'updated_at' => updated_value,
            'attachments' => attachments_by_message.fetch(message.fetch('id').to_s, []),
            'metadata' => metadata
          }
        end
      end
    end

    def message_direction(message)
      return 'note' if message.fetch('type') == 'COMMENT'

      case message.fetch('direction')
      when 'INCOMING' then 'incoming'
      when 'OUTGOING' then 'outgoing'
      else raise ArgumentError, "unsupported message direction: #{message['direction']}"
      end
    end

    def message_content(message)
      text = message['text'].to_s
      text = strip_html(message['richText'].to_s) if text.strip.empty?
      text = '[Nachricht ohne Textinhalt]' if text.strip.empty?
      text[0, Bundle::MAX_MESSAGE_LENGTH]
    end

    def strip_html(value)
      CGI.unescapeHTML(value.gsub(/<br\s*\/?>/i, "\n").gsub(/<\/p>/i, "\n").gsub(/<[^>]+>/, ' '))
         .gsub(/[ \t]+/, ' ').gsub(/ *\n+ */, "\n").strip
    end

    def normalize_phone(value)
      raw = value.to_s.strip
      return nil if raw.empty?

      digits = raw.gsub(/\D/, '')
      normalized = if raw.start_with?('+')
                     "+#{digits}"
                   elsif digits.start_with?('00')
                     "+#{digits[2..]}"
                   elsif digits.start_with?('0')
                     "+49#{digits[1..]}"
                   end
      normalized if normalized&.match?(/\A\+[1-9]\d{1,14}\z/)
    end

    def ordered_timestamps(created_value, updated_value)
      created_time = Time.iso8601(created_value.to_s).utc
      updated_time = Time.iso8601(updated_value.to_s).utc
      updated_time = created_time if updated_time < created_time
      [created_time.iso8601, updated_time.iso8601]
    rescue ArgumentError
      raise ArgumentError, 'invalid HubSpot timestamp'
    end

    def timestamp(record, key)
      Time.iso8601(record.fetch(key)).utc
    rescue ArgumentError
      raise ArgumentError, 'invalid HubSpot timestamp'
    end

    def contact_external_id(contact_id)
      "hubspot-contact:#{contact_id}"
    end

    def conversation_external_id(thread_id)
      "hubspot-thread:#{thread_id}"
    end

    def contact_key(thread)
      contact_id = thread['associatedContactId']&.to_s
      contact_id.to_s.empty? ? "thread-#{thread.fetch('id')}" : contact_id
    end

    def prepare_output!
      FileUtils.mkdir_p(File.join(output_path, 'attachments'), mode: 0o700)
      File.chmod(0o700, output_path)
      File.chmod(0o700, File.join(output_path, 'attachments'))
    end

    def write_bundle(contacts, conversations, messages)
      records = { 'contacts' => contacts, 'conversations' => conversations, 'messages' => messages }
      files = records.to_h do |name, rows|
        bytes = rows.empty? ? '' : rows.map { |row| JSON.generate(row) }.join("\n") + "\n"
        filename = "#{name}.ndjson"
        write_private_file(File.join(output_path, filename), bytes)
        [name, { 'path' => filename, 'sha256' => Digest::SHA256.hexdigest(bytes), 'count' => rows.length }]
      end
      manifest = {
        'schema_version' => 2,
        'source_namespace' => SOURCE_NAMESPACE,
        'export_id' => export_id,
        'tenant_key' => tenant_key,
        'created_at' => created_at.iso8601,
        'knowledge_import' => false,
        'files' => files
      }
      write_private_file(File.join(output_path, 'manifest.json'), JSON.generate(manifest))
    end

    def write_source_archive(threads, events_by_thread, attachments)
      attachments_by_message = attachments.group_by { |attachment| attachment.fetch('source_message_id') }
      events = events_by_thread.sort.flat_map do |thread_id, rows|
        rows.map do |event|
          descriptors = attachments_by_message.fetch(event['id'].to_s, [])
          archive_event(thread_id, event, descriptors)
        end
      end
      records = {
        'source_threads' => threads,
        'source_events' => events,
        'attachments' => attachments
      }
      files = records.to_h do |name, rows|
        bytes = rows.empty? ? '' : rows.map { |row| JSON.generate(row) }.join("\n") + "\n"
        filename = "#{name}.ndjson"
        write_private_file(File.join(output_path, filename), bytes)
        [name, { 'path' => filename, 'sha256' => Digest::SHA256.hexdigest(bytes), 'count' => rows.length }]
      end
      manifest = {
        'schema_version' => 2,
        'source_namespace' => SOURCE_NAMESPACE,
        'export_id' => export_id,
        'tenant_key' => tenant_key,
        'created_at' => created_at.iso8601,
        'knowledge_import' => false,
        'files' => files
      }
      write_private_file(File.join(output_path, 'archive-manifest.json'), JSON.generate(manifest))
    end

    def archive_event(thread_id, event, descriptors)
      copy = Marshal.load(Marshal.dump(event))
      copy['archiveThreadId'] = thread_id
      by_file_id = descriptors.to_h { |descriptor| [descriptor.fetch('external_id').delete_prefix('hubspot-file:'), descriptor] }
      copy['attachments'] = Array(copy['attachments']).map do |attachment|
        next attachment unless attachment['type'] == 'FILE'

        local = by_file_id.fetch(attachment.fetch('fileId').to_s)
        attachment.reject { |key, _value| key == 'url' }.merge('archivedFile' => local.reject { |key, _value| key == 'source_message_id' })
      end
      copy
    end

    def write_private_file(path, bytes)
      File.open(path, File::WRONLY | File::CREAT | File::EXCL, 0o600) { |file| file.write(bytes) }
      File.chmod(0o600, path)
    end
  end
end
