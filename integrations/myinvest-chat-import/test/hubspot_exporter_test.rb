# frozen_string_literal: true

require 'json'
require 'minitest/autorun'
require 'tmpdir'

require_relative '../lib/myinvest_chat_import'

class HubspotExporterTest < Minitest::Test
  class FakeClient
    attr_reader :original_content_requests, :requested_thread_ids

    def initialize
      @requested_thread_ids = []
      @original_content_requests = []
    end

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
      @requested_thread_ids << thread_id
      raise 'unselected thread was fetched' unless thread_id == 'thread-target'
      raise 'unexpected archive routing' if archived

      [
        {
          'id' => 'event-1', 'type' => 'THREAD_INBOX_CHANGE', 'createdAt' => '2024-01-01T10:00:30Z'
        },
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

    def original_content(thread_id, message_id)
      @original_content_requests << [thread_id, message_id]
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

  def test_exports_only_selected_channel_accounts_as_a_valid_private_bundle
    Dir.mktmpdir('hubspot-export-test') do |root|
      output = File.join(root, 'bundle')
      client = FakeClient.new
      result = MyinvestChatImport::HubspotExporter.new(
        client: client,
        output_path: output,
        tenant_key: 'legacy_academy',
        inbox_ids: ['inbox-1'],
        channel_account_ids: ['whatsapp-account'],
        export_id: 'hubspot-export-1',
        created_at: Time.iso8601('2026-08-16T15:00:00Z')
      ).call

      assert_equal({ contacts: 1, conversations: 1, messages: 3, attachments: 1, archived_events: 4, skipped_events: 1 }, result)
      assert_equal ['thread-target'], client.requested_thread_ids
      assert_equal 0o700, File.stat(output).mode & 0o777
      Dir[File.join(output, '**', '*')].select { |path| File.file?(path) }.each do |path|
        assert_equal 0o600, File.stat(path).mode & 0o777
      end

      bundle = MyinvestChatImport::Bundle.load(output)
      assert_equal 'legacy_academy', bundle.tenant_key
      assert_equal 'hubspot-conversations-v3', bundle.source_namespace
      assert_equal 1, bundle.contacts.length
      assert_equal '+491701234567', bundle.contacts.first.fetch('phone_number')
      assert_equal 'ada@example.test', bundle.contacts.first.fetch('email')
      assert_equal %w[incoming outgoing note], bundle.messages.map { |message| message.fetch('direction') }
      assert_equal 'Vollstaendige Nachricht', bundle.messages.first.fetch('content')
      assert_equal [%w[thread-target message-1]], client.original_content_requests
      assert_equal %w[FILE MESSAGE_HEADER], bundle.messages.first.dig('metadata', 'hubspot_attachment_types')
      attachment = bundle.messages.first.fetch('attachments').first
      assert_equal 'Dokument.pdf', attachment.fetch('filename')
      assert_equal '%PDF-test', File.binread(bundle.attachment_path(attachment))

      archive_manifest = JSON.parse(File.read(File.join(output, 'archive-manifest.json')))
      assert_equal 2, archive_manifest.fetch('schema_version')
      assert_equal 4, archive_manifest.dig('files', 'source_events', 'count')
      assert_equal 1, archive_manifest.dig('files', 'attachments', 'count')

      manifest = JSON.parse(File.read(File.join(output, 'manifest.json')))
      assert_equal 2, manifest.fetch('schema_version')
      assert_equal false, manifest.fetch('knowledge_import')
      manifest.fetch('files').each_value do |descriptor|
        bytes = File.binread(File.join(output, descriptor.fetch('path')))
        assert_equal Digest::SHA256.hexdigest(bytes), descriptor.fetch('sha256')
      end
    end
  end

  def test_rejects_unsafe_or_ambiguous_export_configuration
    client = FakeClient.new
    invalid = {
      client: client,
      output_path: '/tmp/not-used',
      tenant_key: 'legacy_academy',
      inbox_ids: [],
      channel_account_ids: ['whatsapp-account'],
      export_id: 'hubspot-export-1',
      created_at: Time.now.utc
    }

    assert_raises(ArgumentError) { MyinvestChatImport::HubspotExporter.new(**invalid) }
    assert_raises(ArgumentError) do
      MyinvestChatImport::HubspotExporter.new(**invalid.merge(inbox_ids: ['inbox-1'], tenant_key: 'unknown'))
    end
  end

  def test_hubspot_client_accepts_opaque_message_ids_but_rejects_path_injection
    client = MyinvestChatImport::HubspotClient.new(access_token: 'test-token', sleeper: ->(_seconds) {}, min_interval: 0)

    assert_equal 'in-abc_123:456', client.send(:path_id!, 'in-abc_123:456')
    assert_raises(ArgumentError) { client.send(:path_id!, '../message') }
    assert_raises(ArgumentError) { client.send(:path_id!, "message\nheader") }
  end
end
