# frozen_string_literal: true

require 'json'
require 'minitest/autorun'
require 'tmpdir'

require_relative '../lib/myinvest_chat_import'

class HubspotEmailExportFixtureTest < Minitest::Test
  class EmailShapedClient
    attr_reader :original_content_requests, :requested_thread_ids, :requested_archived, :thread_pages, :message_pages

    def initialize
      @requested_thread_ids = []
      @requested_archived = []
      @original_content_requests = []
      @thread_pages = Hash.new(0)
      @message_pages = Hash.new(0)
    end

    def threads(inbox_id)
      raise "unexpected inbox #{inbox_id}" unless inbox_id == 'email-inbox'

      Enumerator.new do |yielder|
        @thread_pages[false] += 1
        yielder << {
          'id' => 'email-open', 'inboxId' => inbox_id, 'originalChannelId' => '1002',
          'originalChannelAccountId' => 'email-account', 'associatedContactId' => 'email-contact',
          'status' => 'OPEN', 'archived' => false, 'createdAt' => '2024-02-01T09:00:00Z',
          'latestMessageTimestamp' => '2024-02-01T09:20:00Z'
        }
        yielder << {
          'id' => 'email-other', 'inboxId' => inbox_id, 'originalChannelId' => '1002',
          'originalChannelAccountId' => 'other-mailbox', 'associatedContactId' => 'other-contact',
          'status' => 'OPEN', 'archived' => false, 'createdAt' => '2024-02-01T08:00:00Z',
          'latestMessageTimestamp' => '2024-02-01T08:01:00Z'
        }
        @thread_pages[true] += 1
        yielder << {
          'id' => 'email-archived', 'inboxId' => inbox_id, 'originalChannelId' => '1002',
          'originalChannelAccountId' => 'email-account', 'associatedContactId' => 'email-contact',
          'status' => 'CLOSED', 'archived' => true, 'createdAt' => '2024-01-15T09:00:00Z',
          'closedAt' => '2024-01-15T10:00:00Z', 'latestMessageTimestamp' => '2024-01-15T09:45:00Z'
        }
      end
    end

    def messages(thread_id, archived: false)
      @requested_thread_ids << thread_id
      @requested_archived << [thread_id, archived]
      raise 'unselected mailbox thread was fetched' if thread_id == 'email-other'

      Enumerator.new do |yielder|
        @message_pages[[thread_id, archived]] += 1
        case [thread_id, archived]
        when ['email-open', false]
          yielder << {
            'id' => 'email-assignment', 'type' => 'THREAD_STATUS_CHANGE', 'createdAt' => '2024-02-01T09:00:10Z'
          }
          yielder << {
            'id' => 'email-in-1', 'type' => 'MESSAGE', 'direction' => 'INCOMING',
            'text' => '', 'richText' => '<p>truncated preview</p>',
            'createdAt' => '2024-02-01T09:05:00Z', 'updatedAt' => '2024-02-01T09:05:01Z',
            'truncationStatus' => 'TRUNCATED_TO_MOST_RECENT_REPLY',
            'attachments' => [
              { 'type' => 'MESSAGE_HEADER' },
              { 'type' => 'FILE', 'fileId' => '654', 'name' => 'vertrag.pdf', 'url' => 'https://example.invalid/signed' }
            ]
          }
          yielder << {
            'id' => 'email-out-1', 'type' => 'MESSAGE', 'direction' => 'OUTGOING',
            'text' => 'Antwort aus dem Postfach', 'createdAt' => '2024-02-01T09:20:00Z',
            'updatedAt' => '2024-02-01T09:20:00Z', 'attachments' => []
          }
        when ['email-archived', true]
          yielder << {
            'id' => 'email-archived-in', 'type' => 'MESSAGE', 'direction' => 'INCOMING',
            'text' => 'Archivierte Kundenmail', 'createdAt' => '2024-01-15T09:10:00Z',
            'updatedAt' => '2024-01-15T09:10:00Z', 'attachments' => []
          }
          yielder << {
            'id' => 'email-archived-note', 'type' => 'COMMENT', 'text' => 'Archivierte interne Notiz',
            'createdAt' => '2024-01-15T09:30:00Z', 'updatedAt' => '2024-01-15T09:30:00Z', 'attachments' => []
          }
        else
          raise "unexpected archive routing for #{thread_id} archived=#{archived}"
        end
      end
    end

    def original_content(thread_id, message_id)
      @original_content_requests << [thread_id, message_id]
      raise 'unexpected original-content fetch' unless thread_id == 'email-open' && message_id == 'email-in-1'

      { 'text' => 'Vollstaendige E-Mail mit Verlauf', 'richText' => '<p>Vollstaendige E-Mail mit Verlauf</p>' }
    end

    def download_file(file_id, destination)
      raise 'unexpected file' unless file_id == '654'

      File.binwrite(destination, '%PDF-email')
      { 'filename' => 'vertrag.pdf', 'content_type' => 'application/pdf', 'byte_size' => 10 }
    end

    def contacts(ids)
      raise 'unexpected contact batch' unless ids == ['email-contact']

      {
        'email-contact' => {
          'id' => 'email-contact',
          'properties' => {
            'firstname' => 'Eva', 'lastname' => 'Muster', 'email' => 'EVA@EXAMPLE.TEST',
            'createdate' => '2023-11-01T08:00:00Z', 'lastmodifieddate' => '2024-02-01T09:00:00Z'
          }
        }
      }
    end
  end

  def test_email_shaped_export_covers_allowlist_archived_pagination_and_original_content
    Dir.mktmpdir('hubspot-email-export-test') do |root|
      output = File.join(root, 'bundle')
      client = EmailShapedClient.new
      result = MyinvestChatImport::HubspotExporter.new(
        client: client,
        output_path: output,
        tenant_key: 'saas',
        inbox_ids: ['email-inbox'],
        channel_account_ids: ['email-account'],
        export_id: 'hubspot-email-export-1',
        created_at: Time.iso8601('2026-08-16T16:00:00Z')
      ).call

      assert_equal(
        { contacts: 1, conversations: 2, messages: 4, attachments: 1, archived_events: 5, skipped_events: 1 },
        result
      )
      assert_equal %w[email-archived email-open], client.requested_thread_ids.sort
      assert_includes client.requested_archived, ['email-archived', true]
      assert_includes client.requested_archived, ['email-open', false]
      refute_includes client.requested_thread_ids, 'email-other'
      assert_equal 1, client.thread_pages.fetch(false)
      assert_equal 1, client.thread_pages.fetch(true)
      assert_equal 1, client.message_pages.fetch(['email-open', false])
      assert_equal 1, client.message_pages.fetch(['email-archived', true])
      assert_equal [%w[email-open email-in-1]], client.original_content_requests

      bundle = MyinvestChatImport::Bundle.load(output)
      assert_equal 'saas', bundle.tenant_key
      assert_equal false, JSON.parse(File.read(File.join(output, 'manifest.json'))).fetch('knowledge_import')
      assert_equal false, JSON.parse(File.read(File.join(output, 'archive-manifest.json'))).fetch('knowledge_import')
      assert_equal 2, bundle.conversations.length
      assert_equal 4, bundle.messages.length
      assert_equal 'Vollstaendige E-Mail mit Verlauf', bundle.messages.find { |message|
        message.fetch('external_id') == 'hubspot-message:email-in-1'
      }.fetch('content')
      assert_equal 'note', bundle.messages.find { |message|
        message.fetch('external_id') == 'hubspot-message:email-archived-note'
      }.fetch('direction')
      attachment = bundle.messages.find { |message|
        message.fetch('external_id') == 'hubspot-message:email-in-1'
      }.fetch('attachments').first
      assert_equal 'vertrag.pdf', attachment.fetch('filename')
      assert_equal '%PDF-email', File.binread(bundle.attachment_path(attachment))

      archive_manifest = JSON.parse(File.read(File.join(output, 'archive-manifest.json')))
      assert_equal 5, archive_manifest.dig('files', 'source_events', 'count')
      assert_equal 1, archive_manifest.dig('files', 'attachments', 'count')
      source_events = File.readlines(File.join(output, 'source_events.ndjson'), chomp: true).map { |line| JSON.parse(line) }
      assert_equal 1, source_events.count { |event| event['type'] == 'THREAD_STATUS_CHANGE' }
      assert_equal 3, source_events.count { |event| event['type'] == 'MESSAGE' }
      assert_equal 1, source_events.count { |event| event['type'] == 'COMMENT' }
      file_event = source_events.find { |event| event['id'] == 'email-in-1' }
      refute file_event.fetch('attachments').any? { |attachment_row| attachment_row.key?('url') }
      assert_equal 'attachments/', file_event.dig('attachments').find { |row| row['type'] == 'FILE' }.dig('archivedFile', 'path')[0, 12]

      receipt = MyinvestChatImport::HubspotExportVerifier.new(output).call
      assert_equal false, receipt.fetch('knowledge_import')
      assert_equal 4, receipt.fetch('messages')
      assert_equal 5, receipt.fetch('archived_events')
      assert_equal 1, receipt.fetch('skipped_events')
      assert_equal true, receipt.fetch('source_subset_equal')
      assert_equal true, receipt.fetch('attachment_archive_closed')
    end
  end
end
