# frozen_string_literal: true

require 'digest'
require 'json'
require 'minitest/autorun'
require 'tmpdir'

require_relative '../lib/myinvest_chat_import'

class HubspotExportVerifierTest < Minitest::Test
  class FakeClient
    def threads(inbox_id)
      raise "unexpected inbox #{inbox_id}" unless inbox_id == 'inbox-1'

      [
        {
          'id' => 'thread-target', 'inboxId' => inbox_id, 'originalChannelId' => '1007',
          'originalChannelAccountId' => 'whatsapp-account', 'associatedContactId' => 'contact-1',
          'status' => 'CLOSED', 'createdAt' => '2024-01-01T10:00:00Z',
          'closedAt' => '2024-01-01T10:10:00Z', 'latestMessageTimestamp' => '2024-01-01T10:09:00Z'
        },
        {
          'id' => 'thread-other', 'inboxId' => inbox_id, 'originalChannelId' => '1003',
          'originalChannelAccountId' => 'unselected-account', 'associatedContactId' => 'contact-2',
          'status' => 'OPEN', 'createdAt' => '2024-01-01T11:00:00Z',
          'latestMessageTimestamp' => '2024-01-01T11:01:00Z'
        }
      ]
    end

    def messages(thread_id, archived: false)
      raise 'unselected thread was fetched' unless thread_id == 'thread-target'
      raise 'unexpected archive routing' if archived

      [
        { 'id' => 'event-1', 'type' => 'THREAD_INBOX_CHANGE', 'createdAt' => '2024-01-01T10:00:30Z' },
        {
          'id' => 'message-1', 'type' => 'MESSAGE', 'direction' => 'INCOMING',
          'text' => '', 'richText' => '<p>Hallo &amp; Hilfe</p>',
          'createdAt' => '2024-01-01T10:01:00Z', 'updatedAt' => '2024-01-01T10:01:01Z',
          'truncationStatus' => 'TRUNCATED',
          'attachments' => [
            { 'type' => 'MESSAGE_HEADER' },
            { 'type' => 'FILE', 'fileId' => '987', 'name' => 'Dokument.pdf', 'url' => 'https://example.invalid/expiring' }
          ]
        },
        {
          'id' => 'message-2', 'type' => 'MESSAGE', 'direction' => 'OUTGOING',
          'text' => 'Willkommen', 'createdAt' => '2024-01-01T10:02:00Z',
          'updatedAt' => '2024-01-01T10:02:00Z', 'attachments' => []
        },
        {
          'id' => 'comment-1', 'type' => 'COMMENT', 'text' => 'Interne Notiz',
          'createdAt' => '2024-01-01T10:03:00Z', 'updatedAt' => '2024-01-01T10:03:00Z',
          'attachments' => []
        }
      ]
    end

    def original_content(_thread_id, _message_id)
      { 'text' => 'Vollstaendige Nachricht', 'richText' => '<p>Vollstaendige Nachricht</p>' }
    end

    def download_file(file_id, destination)
      raise 'unexpected file' unless file_id == '987'

      File.binwrite(destination, '%PDF-test')
      { 'filename' => 'Dokument.pdf', 'content_type' => 'application/pdf', 'byte_size' => 9 }
    end

    def contacts(ids)
      raise 'unexpected contact batch' unless ids == ['contact-1']

      {
        'contact-1' => {
          'id' => 'contact-1',
          'properties' => {
            'firstname' => 'Ada', 'lastname' => 'Beispiel', 'email' => 'ADA@EXAMPLE.TEST',
            'phone' => '0170 1234567', 'mobilephone' => '+49 170 1234567',
            'createdate' => '2023-12-01T08:00:00Z', 'lastmodifieddate' => '2024-01-02T08:00:00Z'
          }
        }
      }
    end
  end

  def test_valid_v2_export_emits_aggregate_receipt_without_pii
    with_export do |path|
      receipt = MyinvestChatImport::HubspotExportVerifier.new(path).call

      assert_equal 'hubspot_history_export_verified', receipt.fetch('event')
      assert_equal 2, receipt.fetch('schema_version')
      assert_equal false, receipt.fetch('knowledge_import')
      assert_equal 1, receipt.fetch('contacts')
      assert_equal 1, receipt.fetch('conversations')
      assert_equal 3, receipt.fetch('messages')
      assert_equal 1, receipt.fetch('attachments')
      assert_equal 1, receipt.fetch('archived_threads')
      assert_equal 4, receipt.fetch('archived_events')
      assert_equal 2, receipt.fetch('source_message_events')
      assert_equal 1, receipt.fetch('source_comment_events')
      assert_equal 1, receipt.fetch('skipped_events')
      assert_equal true, receipt.fetch('source_subset_equal')
      assert_equal true, receipt.fetch('attachment_archive_closed')
      assert_equal true, receipt.fetch('import_files_digest_match')
      assert_equal true, receipt.fetch('archive_files_digest_match')
      refute_includes receipt.keys, 'content'
      refute_includes receipt.keys, 'email'
      refute_includes receipt.keys, 'name'
      refute_includes receipt.keys, 'external_id'
      refute_pii(receipt)
    end
  end

  def test_cli_emits_only_aggregate_json
    with_export do |path|
      output = `#{ruby_cmd} #{cli_path} #{path}`
      assert_equal 0, $?.exitstatus, output

      receipt = JSON.parse(output)
      assert_equal 'hubspot_history_export_verified', receipt.fetch('event')
      refute_pii(receipt)
    end
  end

  def test_fails_closed_when_archive_manifest_schema_is_invalid
    with_export do |path|
      rewrite_json(path, 'archive-manifest.json') do |manifest|
        manifest.merge('unexpected' => true)
      end

      error = assert_raises(MyinvestChatImport::ValidationError) { verify(path) }
      assert_equal 'archive_manifest_schema_mismatch', error.code
    end
  end

  def test_fails_closed_when_knowledge_import_is_not_false
    with_export do |path|
      rewrite_json(path, 'archive-manifest.json') do |manifest|
        manifest.merge('knowledge_import' => true)
      end

      assert_raises(MyinvestChatImport::KnowledgeSeparationError) { verify(path) }
    end
  end

  def test_fails_closed_on_declared_archive_digest_or_count_mismatch
    with_export do |path|
      rewrite_json(path, 'archive-manifest.json') do |manifest|
        manifest['files']['source_events']['sha256'] = '0' * 64
        manifest
      end

      error = assert_raises(MyinvestChatImport::ValidationError) { verify(path) }
      assert_equal 'file_digest_mismatch', error.code
    end

    with_export do |path|
      rewrite_json(path, 'archive-manifest.json') do |manifest|
        manifest['files']['attachments']['count'] = 99
        manifest
      end

      error = assert_raises(MyinvestChatImport::ValidationError) { verify(path) }
      assert_equal 'file_count_mismatch', error.code
    end
  end

  def test_fails_closed_on_archive_path_escape
    with_export do |path|
      rewrite_json(path, 'archive-manifest.json') do |manifest|
        manifest['files']['source_events']['path'] = '../source_events.ndjson'
        manifest
      end

      assert_raises(MyinvestChatImport::UnsafePathError) { verify(path) }
    end
  end

  def test_fails_closed_when_message_comment_source_subset_is_not_exact
    with_export do |path|
      drop_message_record(path, 'hubspot-message:comment-1')

      error = assert_raises(MyinvestChatImport::ValidationError) { verify(path) }
      assert_equal 'source_event_subset_mismatch', error.code
    end

    with_export do |path|
      drop_source_event(path, 'comment-1')

      error = assert_raises(MyinvestChatImport::ValidationError) { verify(path) }
      assert_equal 'source_event_subset_mismatch', error.code
    end
  end

  def test_fails_closed_when_attachment_archive_is_not_closed
    with_export do |path|
      rewrite_ndjson(path, 'attachments.ndjson') { |_rows| [] }
      rewrite_json(path, 'archive-manifest.json') do |manifest|
        bytes = File.binread(File.join(path, 'attachments.ndjson'))
        manifest['files']['attachments']['sha256'] = Digest::SHA256.hexdigest(bytes)
        manifest['files']['attachments']['count'] = 0
        manifest
      end

      error = assert_raises(MyinvestChatImport::ValidationError) { verify(path) }
      assert_equal 'attachment_archive_not_closed', error.code
    end
  end

  def test_fails_closed_when_source_event_content_does_not_match_message
    with_export do |path|
      bytes = rewrite_ndjson(path, 'messages.ndjson') do |rows|
        rows.map do |row|
          if row.fetch('external_id') == 'hubspot-message:message-1'
            row.merge('content' => 'Manipuliert')
          else
            row
          end
        end
      end
      rewrite_json(path, 'manifest.json') do |manifest|
        manifest['files']['messages']['sha256'] = Digest::SHA256.hexdigest(bytes)
        manifest['files']['messages']['count'] = bytes.lines.length
        manifest
      end

      error = assert_raises(MyinvestChatImport::ValidationError) { verify(path) }
      assert_equal 'source_event_content_mismatch', error.code
    end
  end

  def test_fails_closed_when_source_event_thread_does_not_match_conversation
    with_export do |path|
      bytes = rewrite_ndjson(path, 'source_events.ndjson') do |rows|
        rows.map do |row|
          if row.fetch('id') == 'message-1'
            row.merge('archiveThreadId' => 'thread-other')
          else
            row
          end
        end
      end
      rewrite_json(path, 'archive-manifest.json') do |manifest|
        manifest['files']['source_events']['sha256'] = Digest::SHA256.hexdigest(bytes)
        manifest['files']['source_events']['count'] = bytes.lines.length
        manifest
      end

      error = assert_raises(MyinvestChatImport::ValidationError) { verify(path) }
      assert_equal 'source_event_thread_mismatch', error.code
    end
  end

  def test_fails_closed_when_url_remains_in_archived_file_attachment
    with_export do |path|
      bytes = rewrite_ndjson(path, 'source_events.ndjson') do |rows|
        rows.map do |row|
          next row unless row.fetch('id') == 'message-1'

          row.merge(
            'attachments' => row.fetch('attachments').map do |attachment|
              next attachment unless attachment['type'] == 'FILE'

              attachment.merge('archivedFile' => attachment.fetch('archivedFile').merge('url' => 'https://example.invalid/secret'))
            end
          )
        end
      end
      rewrite_json(path, 'archive-manifest.json') do |manifest|
        manifest['files']['source_events']['sha256'] = Digest::SHA256.hexdigest(bytes)
        manifest['files']['source_events']['count'] = bytes.lines.length
        manifest
      end

      error = assert_raises(MyinvestChatImport::ValidationError) { verify(path) }
      assert_equal 'url_in_source_archive', error.code
    end
  end

  def test_verifier_reuses_bundle_helpers_and_does_not_duplicate_importer
    source = File.read(File.expand_path('../lib/myinvest_chat_import/hubspot_export_verifier.rb', __dir__))
    cli = File.read(cli_path)

    assert_includes source, 'Bundle.load'
    refute_includes source, 'Importer'
    refute_includes source, 'RailsAdapter'
    refute_includes cli, 'Importer'
    refute_includes cli, 'Account.'
  end

  private

  def verify(path)
    MyinvestChatImport::HubspotExportVerifier.new(path).call
  end

  def with_export
    Dir.mktmpdir('hubspot-export-verifier') do |root|
      output = File.join(root, 'bundle')
      MyinvestChatImport::HubspotExporter.new(
        client: FakeClient.new,
        output_path: output,
        tenant_key: 'legacy_academy',
        inbox_ids: ['inbox-1'],
        channel_account_ids: ['whatsapp-account'],
        export_id: 'hubspot-export-1',
        created_at: Time.iso8601('2026-08-16T15:00:00Z')
      ).call
      yield output
    end
  end

  def rewrite_json(root, name)
    path = File.join(root, name)
    payload = yield JSON.parse(File.read(path))
    File.write(path, JSON.generate(payload))
  end

  def rewrite_ndjson(root, name)
    path = File.join(root, name)
    rows = File.readlines(path, chomp: true).reject(&:empty?).map { |line| JSON.parse(line) }
    updated = yield rows
    bytes = updated.empty? ? '' : "#{updated.map { |row| JSON.generate(row) }.join("\n")}\n"
    File.binwrite(path, bytes)
    bytes
  end

  def drop_message_record(path, external_id)
    bytes = rewrite_ndjson(path, 'messages.ndjson') do |rows|
      rows.reject { |row| row.fetch('external_id') == external_id }
    end
    rewrite_json(path, 'manifest.json') do |manifest|
      manifest['files']['messages']['sha256'] = Digest::SHA256.hexdigest(bytes)
      manifest['files']['messages']['count'] = bytes.empty? ? 0 : bytes.lines.length
      manifest
    end
  end

  def drop_source_event(path, event_id)
    bytes = rewrite_ndjson(path, 'source_events.ndjson') do |rows|
      rows.reject { |row| row.fetch('id') == event_id }
    end
    rewrite_json(path, 'archive-manifest.json') do |manifest|
      manifest['files']['source_events']['sha256'] = Digest::SHA256.hexdigest(bytes)
      manifest['files']['source_events']['count'] = bytes.empty? ? 0 : bytes.lines.length
      manifest
    end
  end

  def refute_pii(receipt)
    serialized = JSON.generate(receipt)
    %w[Ada Beispiel ADA@EXAMPLE.TEST ada@example.test Dokument.pdf Vollstaendige Willkommen Interne hubspot-message: hubspot-contact: thread-target].each do |fragment|
      refute_includes serialized, fragment
    end
    receipt.each_value do |value|
      assert [TrueClass, FalseClass, Integer, String].include?(value.class)
      next unless value.is_a?(String)

      refute_match(/@/, value)
      refute_match(/\b\d{5,}\b/, value)
    end
  end

  def cli_path
    File.expand_path('../bin/verify_hubspot_export.rb', __dir__)
  end

  def ruby_cmd
    RbConfig.ruby
  end
end
