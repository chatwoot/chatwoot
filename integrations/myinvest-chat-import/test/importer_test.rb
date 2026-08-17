# frozen_string_literal: true

require 'digest'
require 'json'
require 'minitest/autorun'
require 'tmpdir'

require_relative '../lib/myinvest_chat_import'
require_relative '../lib/myinvest_chat_import/rails_adapter'

class MyinvestChatImportTest < Minitest::Test
  TENANTS = %w[saas new_academy legacy_academy].freeze

  class MemoryAdapter
    attr_reader :attachments, :callback_count, :contacts, :conversations, :imports, :mappings, :messages

    def initialize
      @accounts = TENANTS.to_h { |tenant| [tenant, "account-#{tenant}"] }
      @attachments = []
      @callback_count = 0
      @contacts = []
      @conversations = []
      @imports = []
      @mappings = {}
      @messages = []
      @next_id = 0
    end

    def with_advisory_lock(_lock_key)
      yield
    end

    def transaction
      snapshot = Marshal.dump([@attachments, @contacts, @conversations, @imports, @mappings, @messages, @next_id])
      yield
    rescue StandardError
      @attachments, @contacts, @conversations, @imports, @mappings, @messages, @next_id = Marshal.load(snapshot)
      raise
    end

    def resolve_account(tenant_key)
      @accounts.fetch(tenant_key)
    end

    def ensure_history_inbox(account_id)
      "inbox-#{account_id}"
    end

    def begin_import(account_id:, export_id_hmac:, bundle_sha256:, total_records:, source_namespace_hmac:, schema_version:)
      existing = @imports.find { |item| item[:account_id] == account_id && item[:export_id_hmac] == export_id_hmac }
      if existing
        raise MyinvestChatImport::FingerprintConflictError if existing[:bundle_sha256] != bundle_sha256

        existing[:status] = 'processing'
        return existing[:id]
      end

      id = next_id
      @imports << {
        id: id, account_id: account_id, export_id_hmac: export_id_hmac, bundle_sha256: bundle_sha256,
        source_namespace_hmac: source_namespace_hmac, schema_version: schema_version,
        total_records: total_records, status: 'processing'
      }
      id
    end

    def find_mapping(account_id:, source_object_type:, source_object_id:)
      @mappings[[account_id, source_object_type, source_object_id]]
    end

    def insert_mapping(attributes)
      key = [attributes.fetch(:account_id), attributes.fetch(:source_object_type), attributes.fetch(:source_object_id)]
      raise 'duplicate mapping' if @mappings.key?(key)

      @mappings[key] = attributes
    end

    def insert_contact(attributes)
      id = next_id
      @contacts << attributes.merge(id: id)
      id
    end

    def ensure_contact_inbox(contact_id:, inbox_id:, source_id:, timestamp:)
      { id: "ci-#{contact_id}-#{inbox_id}", contact_id: contact_id, inbox_id: inbox_id, source_id: source_id, timestamp: timestamp }
    end

    def insert_conversation(attributes)
      id = next_id
      @conversations << attributes.merge(id: id)
      id
    end

    def insert_messages(rows)
      rows.map do |attributes|
        id = next_id
        @messages << attributes.merge(id: id)
        id
      end
    end

    def insert_attachments(rows)
      rows.each do |row|
        raise 'missing local attachment' unless File.file?(row.fetch(:path))

        @attachments << row
      end
    end

    def complete_import(import_id:, processed_records:, stats:)
      record = @imports.find { |item| item[:id] == import_id }
      record.merge!(status: 'completed', processed_records: processed_records, stats: stats)
    end

    def fail_import(import_id:, error_code:)
      record = @imports.find { |item| item[:id] == import_id }
      record&.merge!(status: 'failed', error_code: error_code)
    end

    private

    def next_id
      @next_id += 1
    end
  end

  def test_second_run_is_idempotent
    with_bundle do |path|
      adapter = MemoryAdapter.new
      2.times { import(path, adapter) }

      assert_equal 1, adapter.contacts.length
      assert_equal 1, adapter.conversations.length
      assert_equal 2, adapter.messages.length
      assert_equal 4, adapter.mappings.length
      assert_equal 'completed', adapter.imports.fetch(0).fetch(:status)
    end
  end

  def test_successful_retry_clears_stale_import_errors
    updates = []
    relation = Object.new
    relation.define_singleton_method(:update_all) { |attributes| updates << attributes }
    data_import = Class.new
    data_import.define_singleton_method(:where) { |**| relation }
    data_import.define_singleton_method(:statuses) { { 'completed' => 2 } }

    with_temporary_constant(:DataImport, data_import) do
      Time.define_singleton_method(:current) { Time.now }
      MyinvestChatImport::RailsAdapter.new.complete_import(
        import_id: 7,
        processed_records: 11,
        stats: { 'message' => { 'created' => 11 } }
      )
    ensure
      Time.singleton_class.send(:remove_method, :current)
    end

    assert_nil updates.fetch(0).fetch(:processing_errors)
    assert_nil updates.fetch(0).fetch(:last_error_at)
  end

  def test_identical_external_ids_are_isolated_across_all_three_tenants
    adapter = MemoryAdapter.new

    TENANTS.each do |tenant|
      with_bundle(tenant_key: tenant) { |path| import(path, adapter) }
    end

    assert_equal 3, adapter.contacts.length
    assert_equal 3, adapter.conversations.length
    assert_equal 6, adapter.messages.length
    assert_equal 12, adapter.mappings.length
    assert_equal TENANTS.sort, adapter.contacts.map { |row| row.dig(:additional_attributes, 'tenant_key') }.sort
  end

  def test_import_path_does_not_invoke_model_callbacks
    with_bundle do |path|
      adapter = MemoryAdapter.new
      import(path, adapter)

      assert_equal 0, adapter.callback_count
      source = File.read(File.expand_path('../lib/myinvest_chat_import/rails_adapter.rb', __dir__))
      refute_match(/\.(?:create|save|update|destroy)!?\s*\(/, source)
      assert_includes source, 'insert_all!'
    end
  end

  def test_changed_contact_snapshot_reuses_identity_without_overwriting_the_contact
    adapter = MemoryAdapter.new
    with_bundle { |path| import(path, adapter) }

    changed_contact = default_contacts.fetch(0).merge('name' => 'Changed Name')
    with_bundle(export_id: 'export-2', contacts: [changed_contact]) do |path|
      import(path, adapter)
    end

    assert_equal 1, adapter.contacts.length
    assert_equal 'Ada Example', adapter.contacts.first.fetch(:name)
  end

  def test_changed_message_payload_for_a_mapped_source_id_is_a_conflict
    adapter = MemoryAdapter.new
    with_bundle { |path| import(path, adapter) }

    changed_message = default_messages.fetch(0).merge('content' => 'Manipulated')
    with_bundle(export_id: 'export-2', messages: [changed_message]) do |path|
      assert_raises(MyinvestChatImport::FingerprintConflictError) { import(path, adapter) }
    end

    assert_equal 2, adapter.messages.length
  end

  def test_rejects_manifest_traversal_and_external_attachments
    with_bundle do |path|
      manifest_path = File.join(path, 'manifest.json')
      manifest = JSON.parse(File.read(manifest_path))
      manifest['files']['contacts']['path'] = '../contacts.ndjson'
      File.write(manifest_path, JSON.generate(manifest))

      assert_raises(MyinvestChatImport::UnsafePathError) { MyinvestChatImport::Bundle.load(path) }
    end

    external_attachment = [{ 'url' => 'https://files.example/private.pdf' }]
    message = default_messages.fetch(0).merge('attachments' => external_attachment)
    with_bundle(messages: [message]) do |path|
      assert_raises(MyinvestChatImport::UnsupportedAttachmentError) { MyinvestChatImport::Bundle.load(path) }
    end
  end

  def test_v2_imports_digest_verified_local_attachments_idempotently
    bytes = '%PDF-history'
    digest = Digest::SHA256.hexdigest(bytes)
    attachment = {
      'external_id' => 'hubspot-file:987', 'path' => "attachments/#{digest}", 'sha256' => digest,
      'byte_size' => bytes.bytesize, 'filename' => 'history.pdf', 'content_type' => 'application/pdf'
    }
    message = default_messages.fetch(0).merge('attachments' => [attachment])

    with_bundle(schema_version: 2, messages: [message], attachment_files: { attachment.fetch('path') => bytes }) do |path|
      adapter = MemoryAdapter.new
      2.times { import(path, adapter) }

      assert_equal 1, adapter.attachments.length
      assert_equal 'history.pdf', adapter.attachments.first.fetch(:filename)
      assert_equal Digest::SHA256.hexdigest(File.binread(adapter.attachments.first.fetch(:path))), digest
    end
  end

  def test_v2_rejects_attachment_digest_mismatch_and_symlink
    bytes = 'trusted bytes'
    digest = Digest::SHA256.hexdigest(bytes)
    attachment = {
      'external_id' => 'hubspot-file:987', 'path' => "attachments/#{digest}", 'sha256' => digest,
      'byte_size' => bytes.bytesize, 'filename' => 'history.txt', 'content_type' => 'text/plain'
    }
    message = default_messages.fetch(0).merge('attachments' => [attachment])

    with_bundle(schema_version: 2, messages: [message], attachment_files: { attachment.fetch('path') => 'changed bytes' }) do |path|
      assert_raises(MyinvestChatImport::ValidationError) { MyinvestChatImport::Bundle.load(path) }
    end
    with_bundle(schema_version: 2, messages: [message], attachment_files: { attachment.fetch('path') => bytes }) do |path|
      attachment_path = File.join(path, attachment.fetch('path'))
      target = File.join(path, 'target.txt')
      File.binwrite(target, bytes)
      File.delete(attachment_path)
      File.symlink(target, attachment_path)

      assert_raises(MyinvestChatImport::UnsafePathError) { MyinvestChatImport::Bundle.load(path) }
    end
  end

  def test_history_import_is_explicitly_separate_from_knowledge_ingestion
    with_bundle do |path|
      manifest_path = File.join(path, 'manifest.json')
      manifest = JSON.parse(File.read(manifest_path)).merge('knowledge_import' => true)
      File.write(manifest_path, JSON.generate(manifest))

      assert_raises(MyinvestChatImport::KnowledgeSeparationError) { MyinvestChatImport::Bundle.load(path) }
    end

    source = Dir[File.expand_path('../{bin,lib}/**/*', __dir__)].select { |path| File.file?(path) }.map { |path| File.read(path) }.join("\n")
    %w[agent_knowledge_documents CLAUDE_AGENT_DATABASE CLAUDE_DATABASE_URL].each { |forbidden| refute_includes source, forbidden }
  end

  def test_rejects_invalid_utf8_and_content_over_150k
    with_bundle do |path|
      messages_path = File.join(path, 'messages.ndjson')
      File.binwrite(messages_path, "{\"bad\":\"\xFF\"}\n")
      rewrite_manifest_digest(path, 'messages')

      assert_raises(MyinvestChatImport::InvalidEncodingError) { MyinvestChatImport::Bundle.load(path) }
    end

    message = default_messages.fetch(0).merge('content' => 'x' * 150_001)
    with_bundle(messages: [message]) do |path|
      assert_raises(MyinvestChatImport::ValidationError) { MyinvestChatImport::Bundle.load(path) }
    end
  end

  def test_rejects_oversized_record_file_before_reading
    with_bundle do |path|
      records_path = File.join(path, 'contacts.ndjson')
      File.binwrite(records_path, '{}')

      manifest_path = File.join(path, 'manifest.json')
      manifest = JSON.parse(File.read(manifest_path))
      manifest['files']['contacts']['sha256'] = '0' * 64
      manifest['files']['contacts']['count'] = 1
      File.write(manifest_path, JSON.generate(manifest))

      binread_paths = []
      original_binread = File.method(:binread)
      original_size = File.method(:size)

      File.stub(:size, ->(file_path) {
        file_path == records_path ? MyinvestChatImport::Bundle::MAX_NDJSON_FILE_BYTES + 1 : original_size.call(file_path)
      }) do
        File.stub(:binread, ->(file_path, *args) {
          binread_paths << file_path
          original_binread.call(file_path, *args)
        }) do
          error = assert_raises(MyinvestChatImport::ValidationError) { MyinvestChatImport::Bundle.load(path) }
          assert_equal 'file_too_large', error.code
        end
      end

      refute_includes binread_paths, records_path
    end
  end

  private

  def with_temporary_constant(name, value)
    previous = Object.const_get(name) if Object.const_defined?(name, false)
    Object.send(:remove_const, name) if Object.const_defined?(name, false)
    Object.const_set(name, value)
    yield
  ensure
    Object.send(:remove_const, name) if Object.const_defined?(name, false)
    Object.const_set(name, previous) if previous
  end

  def import(path, adapter)
    bundle = MyinvestChatImport::Bundle.load(path)
    identity = MyinvestChatImport::Identity.new('a' * 64)
    MyinvestChatImport::Importer.new(bundle: bundle, adapter: adapter, identity: identity).call
  end

  def with_bundle(tenant_key: 'saas', export_id: 'export-1', contacts: default_contacts,
                  conversations: default_conversations, messages: default_messages, schema_version: 1,
                  attachment_files: {})
    Dir.mktmpdir('myinvest-chat-import') do |path|
      attachment_files.each do |relative_path, bytes|
        absolute_path = File.join(path, relative_path)
        FileUtils.mkdir_p(File.dirname(absolute_path))
        File.binwrite(absolute_path, bytes)
      end
      records = { 'contacts' => contacts, 'conversations' => conversations, 'messages' => messages }
      files = records.to_h do |name, rows|
        bytes = rows.map { |row| JSON.generate(row) }.join("\n") + "\n"
        filename = "#{name}.ndjson"
        File.binwrite(File.join(path, filename), bytes)
        [name, { 'path' => filename, 'sha256' => Digest::SHA256.hexdigest(bytes), 'count' => rows.length }]
      end
      manifest = {
        'schema_version' => schema_version,
        'source_namespace' => 'academy-export',
        'export_id' => export_id,
        'tenant_key' => tenant_key,
        'created_at' => '2026-08-16T10:00:00Z',
        'knowledge_import' => false,
        'files' => files
      }
      File.binwrite(File.join(path, 'manifest.json'), JSON.generate(manifest))
      yield path
    end
  end

  def rewrite_manifest_digest(path, name)
    manifest_path = File.join(path, 'manifest.json')
    manifest = JSON.parse(File.read(manifest_path))
    bytes = File.binread(File.join(path, manifest.fetch('files').fetch(name).fetch('path')))
    manifest['files'][name]['sha256'] = Digest::SHA256.hexdigest(bytes)
    manifest['files'][name]['count'] = 1
    File.binwrite(manifest_path, JSON.generate(manifest))
  end

  def default_contacts
    [{
      'external_id' => 'contact-1', 'name' => 'Ada Example', 'email' => 'ada@example.test',
      'phone_number' => '+491701234567', 'created_at' => '2024-01-01T10:00:00Z', 'updated_at' => '2024-01-02T10:00:00Z'
    }]
  end

  def default_conversations
    [{
      'external_id' => 'conversation-1', 'contact_external_id' => 'contact-1', 'status' => 'resolved',
      'created_at' => '2024-01-01T10:01:00Z', 'updated_at' => '2024-01-02T10:01:00Z'
    }]
  end

  def default_messages
    [
      {
        'external_id' => 'message-1', 'conversation_external_id' => 'conversation-1', 'direction' => 'incoming',
        'content' => 'Hallo', 'created_at' => '2024-01-01T10:02:00Z', 'updated_at' => '2024-01-01T10:02:00Z', 'attachments' => []
      },
      {
        'external_id' => 'message-2', 'conversation_external_id' => 'conversation-1', 'direction' => 'outgoing',
        'content' => 'Willkommen', 'created_at' => '2024-01-01T10:03:00Z', 'updated_at' => '2024-01-01T10:03:00Z',
        'attachments' => [], 'metadata' => { 'source' => 'legacy-helpdesk' }
      }
    ]
  end
end
