require 'rails_helper'

RSpec.describe DataImports::Intercom::Importer do
  let(:account) { create(:account) }
  let(:data_import) do
    create(
      :data_import, :intercom,
      account: account
    )
  end
  let(:client) { instance_double(DataImports::Intercom::Client) }
  let(:contact_payload) do
    {
      'id' => 'contact_1',
      'external_id' => 'external_1',
      'email' => 'CUSTOMER@Example.com',
      'phone' => '15551234567',
      'name' => 'Customer One',
      'created_at' => 1_700_000_000,
      'updated_at' => 1_700_000_100
    }
  end
  let(:conversation_payload) do
    {
      'id' => 'conversation_1',
      'created_at' => 1_700_000_000,
      'updated_at' => 1_700_000_200,
      'state' => 'closed',
      'open' => false,
      'admin_assignee_id' => 123,
      'team_assignee_id' => 456,
      'contacts' => { 'contacts' => [{ 'id' => 'contact_1' }] },
      'source' => {
        'id' => 'source_1',
        'type' => 'email',
        'delivered_as' => 'customer_initiated',
        'subject' => 'Need help',
        'body' => '<p>Hello there</p>',
        'author' => { 'type' => 'user', 'id' => 'contact_1', 'email' => 'CUSTOMER@example.com' }
      },
      'conversation_parts' => {
        'conversation_parts' => [
          {
            'id' => 'part_1',
            'part_type' => 'comment',
            'body' => '<p>Admin reply</p>',
            'created_at' => 1_700_000_100,
            'updated_at' => 1_700_000_100,
            'author' => { 'type' => 'admin', 'id' => 'admin_1' },
            'attachments' => []
          },
          {
            'id' => 'part_2',
            'part_type' => 'note',
            'body' => '<strong>Internal note</strong>',
            'created_at' => 1_700_000_150,
            'updated_at' => 1_700_000_150,
            'author' => { 'type' => 'admin', 'id' => 'admin_1' },
            'attachments' => []
          }
        ]
      }
    }
  end

  before do
    account.enable_features!('data_import')
    allow(DataImports::Intercom::Client).to receive(:new).with(access_token: 'intercom-token').and_return(client)
    allow(client).to receive(:list_contacts).with(starting_after: nil, per_page: 50).and_return(
      'data' => [contact_payload],
      'total_count' => 1,
      'pages' => { 'next' => nil }
    )
    allow(client).to receive(:list_conversations).with(starting_after: nil, per_page: 10).and_return(
      'conversations' => [{ 'id' => 'conversation_1' }],
      'total_count' => 1,
      'pages' => { 'next' => nil }
    )
    allow(client).to receive(:retrieve_conversation).with('conversation_1').and_return(conversation_payload)
    allow(client).to receive(:retrieve_contact).with('contact_1').and_return(contact_payload)
  end

  it 'imports contacts, conversations, messages, and source-bucket inboxes without normal message creation callbacks', :aggregate_failures do
    described_class.new(data_import: data_import).perform

    contact = account.contacts.find_by!(email: 'customer@example.com')
    expect(contact.name).to eq('Customer One')
    expect(contact.phone_number).to eq('+15551234567')
    expect(contact).to be_lead
    expect(contact.custom_attributes).to include('intercom_contact_id' => 'contact_1')

    inbox = account.inboxes.find_by!(name: 'Intercom Import - Email')
    expect(inbox.channel.additional_attributes).to include('source_bucket' => 'email', 'import_placeholder' => true)

    conversation = account.conversations.find_by!(identifier: 'intercom:conversation_1')
    expect(conversation).to have_attributes(
      status: 'resolved',
      inbox_id: inbox.id,
      contact_id: contact.id
    )
    expect(conversation.additional_attributes.dig('source', 'routing_method')).to eq('source_bucket_api_inbox')

    expect(conversation.messages.order(:created_at).pluck(:content)).to eq(["Need help\n\nHello there", 'Admin reply', 'Internal note'])
    expect(conversation.messages.order(:created_at).map(&:message_type)).to eq(%w[incoming outgoing outgoing])
    expect(conversation.messages.order(:created_at).last.private).to be(true)

    expect(data_import.reload).to be_completed
    expect(data_import.stats).to include(
      'contacts' => include('imported' => 1, 'skipped' => 0, 'total' => 1),
      'conversations' => include('imported' => 1, 'skipped' => 0, 'total' => 1),
      'messages' => include('imported' => 3, 'skipped' => 0, 'total' => 3),
      'errors' => { 'count' => 0 }
    )
    expect(data_import.processed_records).to eq(5)
    expect(data_import.items.imported.count).to eq(2)
    expect(DataImportMapping.where(data_import: data_import).count).to eq(5)
  end

  it 'writes a normal conversation with one message insert and one mapping upsert', :aggregate_failures do
    importer = described_class.new(data_import: data_import)
    message_batch_sizes = []
    mapping_batch_sizes = []
    mapping_upsert_options = []
    allow(Message).to receive(:insert_all!).and_wrap_original do |method, records, **kwargs|
      message_batch_sizes << records.size
      method.call(records, **kwargs)
    end
    allow(DataImportMapping).to receive(:upsert_all).and_wrap_original do |method, records, **kwargs|
      mapping_batch_sizes << records.size
      mapping_upsert_options << kwargs
      method.call(records, **kwargs)
    end
    expect(importer).not_to receive(:create_message)

    importer.perform

    expect(message_batch_sizes).to eq([3])
    expect(mapping_batch_sizes).to eq([3])
    expect(mapping_upsert_options).to contain_exactly(
      include(unique_by: described_class::MESSAGE_MAPPING_UNIQUE_INDEX, record_timestamps: false)
    )
    expect(account.messages.count).to eq(3)
    expect(data_import.reload.stats.dig('messages', 'imported')).to eq(3)
  end

  it 'preserves provider order when imported messages share a timestamp' do
    equal_timestamp_conversation = conversation_payload.deep_dup
    equal_timestamp_conversation['conversation_parts']['conversation_parts'].each do |part|
      part['created_at'] = conversation_payload['created_at']
      part['updated_at'] = conversation_payload['created_at']
    end
    allow(client).to receive(:retrieve_conversation).with('conversation_1').and_return(equal_timestamp_conversation)

    described_class.new(data_import: data_import).perform

    conversation = account.conversations.find_by!(identifier: 'intercom:conversation_1')
    expect(conversation.messages.order(:created_at, :id).pluck(:source_id)).to eq(
      %w[
        intercom:conversation:conversation_1:source:source_1
        intercom:conversation:conversation_1:part:part_1
        intercom:conversation:conversation_1:part:part_2
      ]
    )
  end

  it 'writes conversations in batches of at most 100 messages', :aggregate_failures do
    bulk_conversation = conversation_payload.deep_dup
    template_part = bulk_conversation.dig('conversation_parts', 'conversation_parts').first
    bulk_conversation['conversation_parts']['conversation_parts'] = Array.new(205) do |index|
      template_part.merge(
        'id' => "part_#{index + 1}",
        'created_at' => 1_700_000_100 + index,
        'updated_at' => 1_700_000_100 + index
      )
    end
    allow(client).to receive(:retrieve_conversation).with('conversation_1').and_return(bulk_conversation)
    message_batch_sizes = []
    mapping_batch_sizes = []
    allow(Message).to receive(:insert_all!).and_wrap_original do |method, records, **kwargs|
      message_batch_sizes << records.size
      method.call(records, **kwargs)
    end
    allow(DataImportMapping).to receive(:upsert_all).and_wrap_original do |method, records, **kwargs|
      mapping_batch_sizes << records.size
      method.call(records, **kwargs)
    end
    importer = described_class.new(data_import: data_import)
    expect(importer).to receive(:update_conversation_activity).once.and_call_original

    importer.import_conversations_page

    expect(message_batch_sizes).to eq([100, 100, 6])
    expect(mapping_batch_sizes).to eq([100, 100, 6])
    expect(account.messages.order(:created_at).pick(:source_id)).to eq('intercom:conversation:conversation_1:source:source_1')
    expect(account.messages.count).to eq(206)
    expect(data_import.reload.stats.dig('messages', 'imported')).to eq(206)
  end

  context 'when a bulk message chunk fails' do
    it 'retries a query timeout once and keeps the successful bulk result', :aggregate_failures do
      importer = described_class.new(data_import: data_import)
      mapping_attempts = 0
      allow(importer).to receive(:sleep)
      allow(DataImportMapping).to receive(:upsert_all).and_wrap_original do |method, records, **kwargs|
        mapping_attempts += 1
        raise ActiveRecord::QueryCanceled, 'statement timeout' if mapping_attempts == 1

        method.call(records, **kwargs)
      end
      expect(importer).not_to receive(:fallback_message_entries)

      importer.perform

      expect(mapping_attempts).to eq(2)
      expect(importer).to have_received(:sleep).with(be_between(0.2, 0.5)).once
      expect(account.messages.count).to eq(3)
      expect(data_import.mappings.where(source_object_type: 'message').count).to eq(3)
      expect(data_import.import_errors).to be_empty
      expect(data_import.reload.stats.dig('messages', 'imported')).to eq(3)
    end

    it 'falls back individually after the query timeout retry is exhausted', :aggregate_failures do
      importer = described_class.new(data_import: data_import)
      mapping_attempts = 0
      reindex_transaction_depths = []
      transaction_depth_before_import = Message.connection.open_transactions
      allow(importer).to receive(:sleep)
      allow(importer).to receive(:fallback_message_entries).and_call_original
      allow(importer).to receive(:create_message).and_call_original
      allow(importer).to receive(:reindex_message_for_search).and_wrap_original do |method, message|
        reindex_transaction_depths << Message.connection.open_transactions
        method.call(message)
      end
      allow(DataImportMapping).to receive(:upsert_all) do
        mapping_attempts += 1
        raise ActiveRecord::QueryCanceled, 'statement timeout'
      end

      importer.perform

      expect(mapping_attempts).to eq(2)
      expect(importer).to have_received(:sleep).with(be_between(0.2, 0.5)).once
      expect(importer).to have_received(:fallback_message_entries).once
      expect(importer).to have_received(:create_message).exactly(3).times
      expect(account.messages.count).to eq(3)
      expect(data_import.mappings.where(source_object_type: 'message').count).to eq(3)
      expect(data_import.import_errors).to be_empty
      expect(data_import.reload.stats.dig('messages', 'imported')).to eq(3)
      expect(reindex_transaction_depths).to all(eq(transaction_depth_before_import))
    end

    it 'falls back immediately for a non-timeout database error', :aggregate_failures do
      importer = described_class.new(data_import: data_import)
      mapping_attempts = 0
      allow(importer).to receive(:sleep)
      allow(importer).to receive(:fallback_message_entries).and_call_original
      allow(DataImportMapping).to receive(:upsert_all) do
        mapping_attempts += 1
        raise ActiveRecord::StatementInvalid, 'bulk mapping failed'
      end

      importer.perform

      expect(mapping_attempts).to eq(1)
      expect(importer).not_to have_received(:sleep)
      expect(importer).to have_received(:fallback_message_entries).once
      expect(account.messages.count).to eq(3)
      expect(data_import.import_errors).to be_empty
      expect(data_import.reload.stats.dig('messages', 'imported')).to eq(3)
    end

    it 'validates malformed messages before inserting them through the fallback path', :aggregate_failures do
      malformed_conversation = conversation_payload.deep_dup
      malformed_conversation['source']['subject'] = nil
      malformed_conversation['source']['body'] = nil
      malformed_conversation.dig('conversation_parts', 'conversation_parts').first['created_at'] = { 'unexpected' => true }
      allow(client).to receive(:retrieve_conversation).with('conversation_1').and_return(malformed_conversation)
      importer = described_class.new(data_import: data_import)
      allow(importer).to receive(:bulk_write_message_entries).and_raise(ActiveRecord::StatementInvalid, 'bulk failed')

      importer.perform

      expect(account.messages.pluck(:source_id)).to eq(['intercom:conversation:conversation_1:part:part_2'])
      error = data_import.import_errors.find_by!(
        source_object_type: 'message',
        source_object_id: 'conversation:conversation_1:part:part_1'
      )
      expect(error).to have_attributes(
        error_code: described_class::InvalidMessagePayloadError.name,
        message: 'Intercom message created_at must be a Unix timestamp'
      )
      expect(data_import.reload).to be_completed_with_errors
      expect(data_import.stats.dig('messages', 'imported')).to eq(1)
      expect(data_import.stats.dig('errors', 'count')).to eq(1)
    end

    it 'refreshes fallback entries when another worker repairs a message', :aggregate_failures do
      importer = described_class.new(data_import: data_import)
      allow(importer).to receive(:bulk_write_message_entries).and_raise(ActiveRecord::StatementInvalid, 'bulk failed')
      allow(importer).to receive(:fallback_message_entries).and_wrap_original do |method, conversation, contact, batch_builder, entries|
        source_entry = entries.first
        message = create(
          :message,
          account: account,
          inbox: conversation.inbox,
          conversation: conversation,
          source_id: "intercom:#{source_entry.source_id}",
          created_at: Time.zone.at(source_entry.part['created_at']),
          updated_at: Time.zone.at(source_entry.part['created_at'])
        )
        DataImportMapping.create!(
          account: account,
          data_import: data_import,
          source_provider: 'intercom',
          source_object_type: 'message',
          source_object_id: source_entry.source_id,
          chatwoot_record_type: 'Message',
          chatwoot_record_id: message.id,
          metadata: {}
        )
        method.call(conversation, contact, batch_builder, entries)
      end

      importer.perform

      source_id = 'intercom:conversation:conversation_1:source:source_1'
      expect(account.messages.where(source_id: source_id).count).to eq(1)
      expect(account.messages.count).to eq(3)
      expect(data_import.mappings.where(source_object_type: 'message').count).to eq(3)
      expect(data_import.import_errors).to be_empty
      expect(data_import.reload.stats.dig('messages', 'imported')).to eq(3)
    end

    it 'retries a fallback refresh timeout after the lock transaction rolls back', :aggregate_failures do
      importer = described_class.new(data_import: data_import)
      refresh_attempts = 0
      allow(importer).to receive(:sleep)
      allow(importer).to receive(:bulk_write_message_entries).and_raise(ActiveRecord::StatementInvalid, 'bulk failed')
      allow(DataImports::Intercom::MessageBatchBuilder).to receive(:new).and_wrap_original do |method, **kwargs|
        method.call(**kwargs).tap do |batch_builder|
          allow(batch_builder).to receive(:refresh).and_wrap_original do |refresh, entries|
            refresh_attempts += 1
            raise ActiveRecord::QueryCanceled, 'statement timeout' if refresh_attempts == 1

            refresh.call(entries)
          end
        end
      end

      importer.perform

      expect(refresh_attempts).to eq(4)
      expect(importer).to have_received(:sleep).with(be_between(0.2, 0.5)).once
      expect(account.messages.count).to eq(3)
      expect(data_import.mappings.where(source_object_type: 'message').count).to eq(3)
      expect(data_import.import_errors).to be_empty
      expect(data_import.reload.stats.dig('messages', 'imported')).to eq(3)
    end
  end

  it 'isolates a malformed message payload while importing valid messages', :aggregate_failures do
    malformed_conversation = conversation_payload.deep_dup
    malformed_conversation['source']['subject'] = nil
    malformed_conversation['source']['body'] = nil
    malformed_conversation.dig('conversation_parts', 'conversation_parts').first['created_at'] = { 'unexpected' => true }
    allow(client).to receive(:retrieve_conversation).with('conversation_1').and_return(malformed_conversation)
    importer = described_class.new(data_import: data_import)
    expect(importer).not_to receive(:fallback_message_entries)

    importer.perform

    expect(account.messages.pluck(:source_id)).to eq(['intercom:conversation:conversation_1:part:part_2'])
    error = data_import.import_errors.find_by!(
      source_object_type: 'message',
      source_object_id: 'conversation:conversation_1:part:part_1'
    )
    expect(error).to have_attributes(
      error_code: described_class::InvalidMessagePayloadError.name,
      message: 'Intercom message created_at must be a Unix timestamp'
    )
    expect(data_import.import_errors.where(source_object_type: 'message').count).to eq(1)
    expect(data_import.reload).to be_completed_with_errors
    expect(data_import.stats.dig('messages', 'imported')).to eq(1)
    expect(data_import.stats.dig('errors', 'count')).to eq(1)
  end

  it 'isolates an out-of-range message timestamp while importing valid messages', :aggregate_failures do
    malformed_conversation = conversation_payload.deep_dup
    malformed_conversation['source']['subject'] = nil
    malformed_conversation['source']['body'] = nil
    malformed_conversation.dig('conversation_parts', 'conversation_parts').first['created_at'] = Float::INFINITY
    allow(client).to receive(:retrieve_conversation).with('conversation_1').and_return(malformed_conversation)
    importer = described_class.new(data_import: data_import)
    expect(importer).not_to receive(:fallback_message_entries)

    importer.perform

    expect(account.messages.pluck(:source_id)).to eq(['intercom:conversation:conversation_1:part:part_2'])
    error = data_import.import_errors.find_by!(
      source_object_type: 'message',
      source_object_id: 'conversation:conversation_1:part:part_1'
    )
    expect(error).to have_attributes(
      error_code: described_class::InvalidMessagePayloadError.name,
      message: 'Intercom message created_at must be a Unix timestamp'
    )
    expect(data_import.import_errors.where(source_object_type: 'message').count).to eq(1)
    expect(data_import.reload).to be_completed_with_errors
    expect(data_import.stats.dig('messages', 'imported')).to eq(1)
    expect(data_import.stats.dig('errors', 'count')).to eq(1)
  end

  it 'imports historical records without dispatching record events or outbound side effects', :aggregate_failures do
    dispatched_events = []
    allow(Rails.configuration.dispatcher).to receive(:dispatch) do |event_name, *_args|
      dispatched_events << event_name
    end
    clear_enqueued_jobs

    described_class.new(data_import: data_import).perform

    record_events = [
      Events::Types::CONTACT_CREATED,
      Events::Types::CONTACT_UPDATED,
      Events::Types::CONVERSATION_CREATED,
      Events::Types::CONVERSATION_UPDATED,
      Events::Types::CONVERSATION_STATUS_CHANGED,
      Events::Types::ASSIGNEE_CHANGED,
      Events::Types::TEAM_CHANGED,
      Events::Types::MESSAGE_CREATED,
      Events::Types::FIRST_REPLY_CREATED,
      Events::Types::REPLY_CREATED
    ]
    side_effect_jobs = [SendReplyJob, EventDispatcherJob, ActionCableBroadcastJob, WebhookJob, HookJob]

    expect(dispatched_events & record_events).to be_empty
    expect(enqueued_jobs.pluck(:job) & side_effect_jobs).to be_empty
    expect(Notification.where(account: account)).to be_empty
  end

  context 'when Intercom contact activity timestamps are available' do
    let(:contact_payload) do
      super().merge('last_seen_at' => 1_700_000_050, 'last_replied_at' => 1_700_000_090)
    end

    it 'prefers last_seen_at for contact activity' do
      described_class.new(data_import: data_import).import_contacts_page

      contact = account.contacts.find_by!(email: 'customer@example.com')
      expect(contact.last_activity_at).to eq(Time.zone.at(1_700_000_050))
    end
  end

  context 'when Intercom contact last_seen_at is unavailable' do
    let(:contact_payload) do
      super().merge('last_seen_at' => nil, 'last_replied_at' => 1_700_000_090)
    end

    it 'falls back to last_replied_at for contact activity' do
      described_class.new(data_import: data_import).import_contacts_page

      contact = account.contacts.find_by!(email: 'customer@example.com')
      expect(contact.last_activity_at).to eq(Time.zone.at(1_700_000_090))
    end
  end

  it 'leaves contact activity blank when Intercom activity timestamps are unavailable' do
    described_class.new(data_import: data_import).import_contacts_page

    contact = account.contacts.find_by!(email: 'customer@example.com')
    expect(contact.last_activity_at).to be_nil
  end

  it 'updates message totals by delta when a conversation page is retried' do
    importer = described_class.new(data_import: data_import)

    importer.import_conversations_page
    importer.import_conversations_page

    expect(data_import.reload.stats.dig('messages', 'total')).to eq(3)
    item = data_import.items.find_by!(source_object_type: 'conversation', source_object_id: 'conversation_1')
    expect(item.metadata['message_total_contribution']).to eq(3)
  end

  it 'uses smaller conversation pages while retaining the contact page size' do
    importer = described_class.new(data_import: data_import)

    importer.import_contacts_page
    importer.import_conversations_page

    expect(client).to have_received(:list_contacts).with(starting_after: nil, per_page: 50)
    expect(client).to have_received(:list_conversations).with(starting_after: nil, per_page: 10)
  end

  it 'reconciles imported message stats from same-run mappings on retry' do
    described_class.new(data_import: data_import).import_conversations_page
    stats = data_import.reload.stats.deep_dup
    stats['messages']['imported'] = 0
    data_import.update!(stats: stats)
    importer = described_class.new(data_import: data_import)
    expect(importer).to receive(:reconcile_message_stats).once.ordered.and_call_original
    expect(importer).to receive(:update_cursor).with('conversations', nil).once.ordered.and_call_original

    importer.import_conversations_page

    expect(data_import.reload.stats.dig('messages', 'imported')).to eq(3)
  end

  it 'retries a query timeout during deferred message stats reconciliation', :aggregate_failures do
    described_class.new(data_import: data_import).import_conversations_page
    stats = data_import.reload.stats.deep_dup
    stats['messages']['imported'] = 0
    data_import.update!(stats: stats)
    importer = described_class.new(data_import: data_import)
    reconciliation_attempts = 0
    allow(importer).to receive(:sleep)
    allow(importer).to receive(:reconcile_message_stats).and_wrap_original do |method|
      reconciliation_attempts += 1
      raise ActiveRecord::QueryCanceled, 'statement timeout' if reconciliation_attempts == 1

      method.call
    end

    importer.import_conversations_page

    expect(reconciliation_attempts).to eq(2)
    expect(importer).to have_received(:sleep).with(be_between(0.2, 0.5)).once
    expect(data_import.reload.stats.dig('messages', 'imported')).to eq(3)
  end

  it 'indexes imported messages for advanced search' do
    allow(ChatwootApp).to receive(:advanced_search_allowed?).and_return(true)
    allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(false)
    reindexed_message_ids = []
    reindex_transaction_depths = []
    transaction_depth_before_import = Message.connection.open_transactions
    original_reindex_for_search = Message.instance_method(:reindex_for_search)
    Message.define_method(:reindex_for_search) do
      reindexed_message_ids << id
      reindex_transaction_depths << self.class.connection.open_transactions
    end
    Message.__send__(:private, :reindex_for_search)

    described_class.new(data_import: data_import).perform

    expect(reindexed_message_ids).to match_array(Message.where(account_id: account.id).pluck(:id))
    expect(reindex_transaction_depths).to all(eq(transaction_depth_before_import))
  ensure
    Message.define_method(:reindex_for_search, original_reindex_for_search)
    Message.__send__(:private, :reindex_for_search)
  end

  it 'keeps imported messages successful when search reindexing fails', :aggregate_failures do
    allow(ChatwootApp).to receive(:advanced_search_allowed?).and_return(true)
    allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(false)
    # rubocop:disable RSpec/AnyInstance
    allow_any_instance_of(Message).to receive(:reindex_for_search).and_raise(StandardError, 'search unavailable')
    # rubocop:enable RSpec/AnyInstance

    described_class.new(data_import: data_import).perform

    message = account.messages.find_by!(source_id: 'intercom:conversation:conversation_1:source:source_1')
    mapping = data_import.mappings.find_by!(source_object_type: 'message', source_object_id: 'conversation:conversation_1:source:source_1')
    expect(mapping.chatwoot_record).to eq(message)
    expect(data_import.reload).to be_completed
    expect(data_import.import_errors.exists?).to be(false)
    expect(data_import.stats.dig('messages', 'imported')).to eq(3)
  end

  describe '#start!' do
    it 'does not overwrite an import abandoned by another process', :aggregate_failures do
      importer = described_class.new(data_import: data_import)

      DataImport.find(data_import.id).update!(
        status: :abandoned,
        abandoned_at: Time.current
      )

      expect(importer.start!).to be_nil
      expect(data_import.reload).to be_abandoned
      expect(data_import.started_at).to be_nil
    end
  end

  describe '#perform' do
    it 'stops when the import was abandoned before processing starts' do
      importer = described_class.new(data_import: data_import)
      DataImport.find(data_import.id).update!(
        status: :abandoned,
        abandoned_at: Time.current
      )

      expect(client).not_to receive(:list_contacts)

      importer.perform

      expect(data_import.reload).to be_abandoned
    end
  end

  describe '#import_conversations_page' do
    it 'stops an in-flight page when a newer import run takes over', :aggregate_failures do
      run_id = 'intercom-run-1'
      data_import.update!(source_metadata: { DataImport::ACTIVE_INTERCOM_IMPORT_RUN_ID_KEY => run_id })
      allow(client).to receive(:list_conversations).with(starting_after: nil, per_page: 10).and_return(
        'conversations' => [{ 'id' => 'conversation_1' }, { 'id' => 'conversation_2' }],
        'pages' => { 'next' => { 'starting_after' => 'next-conversation-cursor' } }
      )
      allow(client).to receive(:retrieve_conversation).with('conversation_1') do
        data_import.update!(source_metadata: { DataImport::ACTIVE_INTERCOM_IMPORT_RUN_ID_KEY => 'new-run' })
        conversation_payload
      end

      result = described_class.new(data_import: data_import, run_id: run_id).import_conversations_page

      expect(result).to be_done
      expect(client).not_to have_received(:retrieve_conversation).with('conversation_2')
      expect(account.conversations.where(identifier: 'intercom:conversation_1')).to be_empty
      expect(account.contacts.where(email: 'customer@example.com')).to be_empty
      expect(data_import.reload.cursor.dig('conversations', 'starting_after')).to be_nil
    end

    it 'heartbeats at most once per minute while processing conversation message batches' do
      freeze_time do
        started_at = Time.current
        long_conversation = conversation_payload.deep_dup
        template_part = long_conversation.dig('conversation_parts', 'conversation_parts').first
        long_conversation['conversation_parts']['conversation_parts'] = Array.new(400) do |index|
          template_part.merge('id' => "part_#{index + 1}")
        end
        allow(client).to receive(:retrieve_conversation).with('conversation_1').and_return(long_conversation)
        heartbeat_times = []
        allow(data_import).to receive(:touch).and_wrap_original do |method|
          heartbeat_times << Time.current
          method.call
        end
        importer = described_class.new(data_import: data_import)
        empty_result = described_class::MessageBatchResult.new(
          imported_entries: [],
          skipped_entries: [],
          current_entries: [],
          previous_entries: [],
          messages: []
        )
        allow(importer).to receive(:bulk_write_message_entries) do
          travel 30.seconds
          empty_result
        end

        importer.import_conversations_page

        expect(heartbeat_times).to eq([started_at + 1.minute, started_at + 2.minutes])
        expect(importer).to have_received(:bulk_write_message_entries).exactly(5).times
      end
    end

    it 'stops batches without heartbeating or persisting stale stats when a newer run takes over', :aggregate_failures do
      freeze_time do
        run_id = 'intercom-run-1'
        data_import.update!(source_metadata: { DataImport::ACTIVE_INTERCOM_IMPORT_RUN_ID_KEY => run_id })
        long_conversation = conversation_payload.deep_dup
        template_part = long_conversation.dig('conversation_parts', 'conversation_parts').first
        long_conversation['conversation_parts']['conversation_parts'] = Array.new(100) do |index|
          template_part.merge('id' => "part_#{index + 1}")
        end
        allow(client).to receive(:retrieve_conversation).with('conversation_1').and_return(long_conversation)
        allow(data_import).to receive(:touch).and_call_original
        importer = described_class.new(data_import: data_import, run_id: run_id)
        batch_write_count = 0
        allow(importer).to receive(:bulk_write_message_entries).and_wrap_original do |method, *args|
          result = method.call(*args)
          batch_write_count += 1
          if batch_write_count == 1
            DataImport.find(data_import.id).update!(source_metadata: { DataImport::ACTIVE_INTERCOM_IMPORT_RUN_ID_KEY => 'new-run' })
          end
          result
        end

        importer.import_conversations_page

        expect(importer).to have_received(:bulk_write_message_entries).once
        expect(data_import).not_to have_received(:touch)
        expect(data_import.reload.stats.dig('conversations', 'imported')).to eq(0)
        expect(account.messages.count).to eq(100)
      end
    end

    it 'does not persist stale stats when a newer run takes over during the final batch', :aggregate_failures do
      run_id = 'intercom-run-1'
      data_import.update!(source_metadata: { DataImport::ACTIVE_INTERCOM_IMPORT_RUN_ID_KEY => run_id })
      importer = described_class.new(data_import: data_import, run_id: run_id)
      allow(importer).to receive(:bulk_write_message_entries).and_wrap_original do |method, *args|
        method.call(*args).tap do
          DataImport.find(data_import.id).update!(source_metadata: { DataImport::ACTIVE_INTERCOM_IMPORT_RUN_ID_KEY => 'new-run' })
        end
      end

      importer.import_conversations_page

      conversation = account.conversations.find_by!(identifier: 'intercom:conversation_1')
      expect(conversation.messages.count).to eq(3)
      expect(data_import.reload.stats.dig('conversations', 'imported')).to eq(0)
    end

    it 'does not persist stale stats when a newer run takes over during the final prefetch fallback entry', :aggregate_failures do
      run_id = 'intercom-run-1'
      data_import.update!(source_metadata: { DataImport::ACTIVE_INTERCOM_IMPORT_RUN_ID_KEY => run_id })
      importer = described_class.new(data_import: data_import, run_id: run_id)
      allow(importer).to receive(:sleep)
      allow(DataImports::Intercom::MessageBatchBuilder).to receive(:new).and_wrap_original do |method, **kwargs|
        method.call(**kwargs).tap do |batch_builder|
          allow(batch_builder).to receive(:perform).and_wrap_original do |perform, *args|
            raise ActiveRecord::QueryCanceled, 'statement timeout' if args.empty?

            perform.call(*args)
          end
        end
      end
      allow(importer).to receive(:import_unprepared_message).and_wrap_original do |method, *args|
        method.call(*args).tap do
          source_entry = args.last
          next unless source_entry.dig(:part, 'id') == 'part_2'

          DataImport.find(data_import.id).update!(source_metadata: { DataImport::ACTIVE_INTERCOM_IMPORT_RUN_ID_KEY => 'new-run' })
        end
      end
      expect(importer).not_to receive(:update_conversation_activity)

      importer.import_conversations_page

      expect(importer).to have_received(:sleep).with(be_between(0.2, 0.5)).once
      expect(importer).to have_received(:import_unprepared_message).exactly(3).times
      expect(account.messages.count).to eq(3)
      expect(data_import.reload.stats).to include(
        'conversations' => include('imported' => 0),
        'messages' => include('imported' => 0)
      )
    end

    it 'does not write prefetch fallback entries after a newer run takes over', :aggregate_failures do
      run_id = 'intercom-run-1'
      data_import.update!(source_metadata: { DataImport::ACTIVE_INTERCOM_IMPORT_RUN_ID_KEY => run_id })
      importer = described_class.new(data_import: data_import, run_id: run_id)
      allow(importer).to receive(:sleep)
      allow(DataImports::Intercom::MessageBatchBuilder).to receive(:new).and_wrap_original do |method, **kwargs|
        method.call(**kwargs).tap do |batch_builder|
          allow(batch_builder).to receive(:perform).and_wrap_original do |perform, *args|
            raise ActiveRecord::QueryCanceled, 'statement timeout' if args.empty?

            perform.call(*args)
          end
        end
      end
      allow(importer).to receive(:import_unprepared_message).and_wrap_original do |method, *args|
        DataImport.find(data_import.id).update!(
          source_metadata: { DataImport::ACTIVE_INTERCOM_IMPORT_RUN_ID_KEY => 'new-run' }
        )
        method.call(*args)
      end

      importer.import_conversations_page

      expect(importer).to have_received(:import_unprepared_message).once
      expect(account.messages).to be_empty
      expect(data_import.mappings.where(source_object_type: 'message')).to be_empty
    end

    it 'stops individual fallback entries when a newer run takes over', :aggregate_failures do
      run_id = 'intercom-run-1'
      data_import.update!(source_metadata: { DataImport::ACTIVE_INTERCOM_IMPORT_RUN_ID_KEY => run_id })
      importer = described_class.new(data_import: data_import, run_id: run_id)
      allow(importer).to receive(:bulk_write_message_entries).and_raise(ActiveRecord::StatementInvalid, 'bulk failed')
      allow(importer).to receive(:fallback_message_entry).and_wrap_original do |method, *args|
        method.call(*args).tap do
          DataImport.find(data_import.id).update!(source_metadata: { DataImport::ACTIVE_INTERCOM_IMPORT_RUN_ID_KEY => 'new-run' })
        end
      end

      importer.import_conversations_page

      expect(importer).to have_received(:fallback_message_entry).once
      expect(account.messages.count).to eq(1)
      expect(data_import.reload.stats.dig('conversations', 'imported')).to eq(0)
    end

    it 'reconciles conversation stats when a superseded run is retried', :aggregate_failures do
      freeze_time do
        run_id = 'intercom-run-1'
        next_run_id = 'intercom-run-2'
        data_import.update!(source_metadata: { DataImport::ACTIVE_INTERCOM_IMPORT_RUN_ID_KEY => run_id })
        importer = described_class.new(data_import: data_import, run_id: run_id)
        allow(importer).to receive(:bulk_write_message_entries).and_wrap_original do |method, *args|
          method.call(*args).tap do
            DataImport.find(data_import.id).update!(source_metadata: { DataImport::ACTIVE_INTERCOM_IMPORT_RUN_ID_KEY => next_run_id })
          end
        end

        importer.import_conversations_page
        expect(data_import.reload.stats.dig('conversations', 'imported')).to eq(0)

        retry_importer = described_class.new(data_import: data_import, run_id: next_run_id)
        retry_importer.import_conversations_page
        retry_importer.finish!

        expect(data_import.reload.stats.dig('conversations', 'imported')).to eq(1)
        expect(data_import.processed_records).to eq(5)
      end
    end

    it 'rolls back a newly inserted conversation when mapping persistence fails', :aggregate_failures do
      importer = described_class.new(data_import: data_import)
      allow(importer).to receive(:record_mapping).and_wrap_original do |method, object_type, source_id, record, metadata:|
        raise StandardError, 'mapping failed' if object_type == 'conversation'

        method.call(object_type, source_id, record, metadata: metadata)
      end

      importer.import_conversations_page

      expect(account.conversations.where(identifier: 'intercom:conversation_1')).to be_empty
      item = data_import.items.find_by!(source_object_type: 'conversation', source_object_id: 'conversation_1')
      expect(item).to be_failed
      expect(item.last_error_message).to eq('mapping failed')
    end

    it 'rolls back a newly inserted contact when mapping persistence fails', :aggregate_failures do
      sparse_contact = contact_payload.slice('id', 'name', 'created_at', 'updated_at')
      allow(client).to receive(:retrieve_contact).with('contact_1').and_return(sparse_contact)
      importer = described_class.new(data_import: data_import)
      allow(importer).to receive(:record_mapping).and_wrap_original do |method, object_type, source_id, record, metadata:|
        raise StandardError, 'mapping failed' if object_type == 'contact'

        method.call(object_type, source_id, record, metadata: metadata)
      end

      importer.import_conversations_page

      expect(account.contacts.where(name: 'Customer One')).to be_empty
      expect(data_import.mappings.where(source_object_type: 'contact', source_object_id: 'contact_1')).to be_empty
      contact_item = data_import.items.find_by!(source_object_type: 'contact', source_object_id: 'contact_1')
      expect(contact_item).to be_failed
      expect(contact_item.last_error_message).to eq('mapping failed')
    end

    it 'rolls back a newly inserted message when mapping persistence fails', :aggregate_failures do
      importer = described_class.new(data_import: data_import)
      allow(DataImportMapping).to receive(:upsert_all).and_raise(ActiveRecord::StatementInvalid, 'bulk mapping failed')
      allow(importer).to receive(:record_message_mapping).and_wrap_original do |method, entry, message|
        raise StandardError, 'mapping failed' if entry.source_id == 'conversation:conversation_1:source:source_1'

        method.call(entry, message)
      end

      importer.import_conversations_page

      conversation = account.conversations.find_by!(identifier: 'intercom:conversation_1')
      expect(conversation.messages.where(source_id: 'intercom:conversation:conversation_1:source:source_1')).to be_empty
      error = data_import.import_errors.find_by!(
        source_object_type: 'message',
        source_object_id: 'conversation:conversation_1:source:source_1'
      )
      expect(error).to have_attributes(error_code: 'StandardError', message: 'mapping failed')
    end

    it 'retries a contact query timeout after rolling back the first transaction', :aggregate_failures do
      importer = described_class.new(data_import: data_import)
      mapping_attempts = 0
      allow(importer).to receive(:sleep)
      allow(importer).to receive(:record_mapping).and_wrap_original do |method, object_type, source_id, record, metadata:|
        if object_type == 'contact'
          mapping_attempts += 1
          raise ActiveRecord::QueryCanceled, 'statement timeout' if mapping_attempts == 1
        end

        method.call(object_type, source_id, record, metadata: metadata)
      end

      importer.import_contacts_page

      expect(mapping_attempts).to eq(2)
      expect(importer).to have_received(:sleep).with(be_between(0.2, 0.5)).once
      expect(account.contacts.where(email: 'customer@example.com').count).to eq(1)
      expect(data_import.mappings.where(source_object_type: 'contact', source_object_id: 'contact_1').count).to eq(1)
      expect(data_import.import_errors).to be_empty
      expect(data_import.reload.stats.dig('contacts', 'imported')).to eq(1)
    end

    it 'retries a message query timeout after rolling back the first transaction', :aggregate_failures do
      importer = described_class.new(data_import: data_import)
      mapping_attempts = 0
      target_source_id = 'conversation:conversation_1:part:part_1'
      allow(DataImportMapping).to receive(:upsert_all).and_raise(ActiveRecord::StatementInvalid, 'bulk unavailable')
      allow(importer).to receive(:sleep)
      allow(importer).to receive(:record_message_mapping).and_wrap_original do |method, entry, message|
        if entry.source_id == target_source_id
          mapping_attempts += 1
          raise ActiveRecord::QueryCanceled, 'statement timeout' if mapping_attempts == 1
        end

        method.call(entry, message)
      end

      importer.import_conversations_page

      conversation = account.conversations.find_by!(identifier: 'intercom:conversation_1')
      expect(mapping_attempts).to eq(2)
      expect(importer).to have_received(:sleep).with(be_between(0.2, 0.5)).once
      expect(conversation.messages.where(source_id: "intercom:#{target_source_id}").count).to eq(1)
      expect(data_import.mappings.where(source_object_type: 'message', source_object_id: target_source_id).count).to eq(1)
      expect(data_import.import_errors).to be_empty
      expect(data_import.reload.stats.dig('messages', 'imported')).to eq(3)
    end

    it 'records one message failure only after the query timeout retry is exhausted', :aggregate_failures do
      importer = described_class.new(data_import: data_import)
      mapping_attempts = 0
      target_source_id = 'conversation:conversation_1:part:part_1'
      allow(DataImportMapping).to receive(:upsert_all).and_raise(ActiveRecord::StatementInvalid, 'bulk unavailable')
      allow(importer).to receive(:sleep)
      allow(importer).to receive(:record_message_mapping).and_wrap_original do |method, entry, message|
        if entry.source_id == target_source_id
          mapping_attempts += 1
          raise ActiveRecord::QueryCanceled, 'statement timeout'
        end

        method.call(entry, message)
      end

      importer.import_conversations_page

      conversation = account.conversations.find_by!(identifier: 'intercom:conversation_1')
      error = data_import.import_errors.find_by!(source_object_type: 'message', source_object_id: target_source_id)
      expect(mapping_attempts).to eq(2)
      expect(importer).to have_received(:sleep).with(be_between(0.2, 0.5)).once
      expect(conversation.messages.where(source_id: "intercom:#{target_source_id}")).to be_empty
      expect(error).to have_attributes(error_code: 'ActiveRecord::QueryCanceled', message: 'statement timeout')
      expect(data_import.reload.stats.dig('errors', 'count')).to eq(1)
    end
  end

  describe '#finish!' do
    it 'does not overwrite an import abandoned by another process' do
      data_import.update!(status: :processing)
      importer = described_class.new(data_import: data_import)

      DataImport.find(data_import.id).update!(
        status: :abandoned,
        abandoned_at: Time.current
      )

      importer.finish!

      expect(data_import.reload).to be_abandoned
      expect(data_import.completed_at).to be_nil
    end

    it 'does not finish an import after a newer run takes over', :aggregate_failures do
      run_id = 'intercom-run-1'
      data_import.update!(
        status: :processing,
        source_metadata: { DataImport::ACTIVE_INTERCOM_IMPORT_RUN_ID_KEY => run_id }
      )
      importer = described_class.new(data_import: data_import, run_id: run_id)

      DataImport.find(data_import.id).update!(
        status: :pending,
        source_metadata: { DataImport::ACTIVE_INTERCOM_IMPORT_RUN_ID_KEY => 'intercom-run-2' }
      )

      importer.finish!

      expect(data_import.reload).to be_pending
      expect(data_import.completed_at).to be_nil
    end
  end

  describe '#fail!' do
    it 'does not overwrite an import abandoned by another process', :aggregate_failures do
      data_import.update!(status: :processing)
      importer = described_class.new(data_import: data_import)

      DataImport.find(data_import.id).update!(
        status: :abandoned,
        abandoned_at: Time.current
      )

      importer.fail!(StandardError.new('boom'))

      expect(data_import.reload).to be_abandoned
      expect(data_import.last_error_at).to be_nil
      expect(data_import.import_errors.exists?).to be(false)
    end

    it 'does not fail an import after a newer run takes over', :aggregate_failures do
      run_id = 'intercom-run-1'
      data_import.update!(
        status: :processing,
        source_metadata: { DataImport::ACTIVE_INTERCOM_IMPORT_RUN_ID_KEY => run_id }
      )
      importer = described_class.new(data_import: data_import, run_id: run_id)

      DataImport.find(data_import.id).update!(
        status: :pending,
        source_metadata: { DataImport::ACTIVE_INTERCOM_IMPORT_RUN_ID_KEY => 'intercom-run-2' }
      )

      importer.fail!(StandardError.new('boom'))

      expect(data_import.reload).to be_pending
      expect(data_import.last_error_at).to be_nil
      expect(data_import.import_errors.exists?).to be(false)
    end
  end

  context 'when the Intercom records were imported by an earlier run' do
    let(:next_data_import) do
      create(
        :data_import, :intercom,
        account: account
      )
    end

    it 'records the already mapped records as skipped for the current import run', :aggregate_failures do
      described_class.new(data_import: data_import).perform

      described_class.new(data_import: next_data_import).perform

      expect(next_data_import.reload.stats).to include(
        'contacts' => include('imported' => 0, 'skipped' => 1, 'total' => 1),
        'conversations' => include('imported' => 0, 'skipped' => 1, 'total' => 1),
        'messages' => include('imported' => 0, 'skipped' => 3, 'total' => 3),
        'errors' => { 'count' => 0 }
      )
      expect(next_data_import).to be_completed
      expect(next_data_import.total_records).to eq(5)
      expect(next_data_import.processed_records).to eq(0)
      expect(next_data_import.items.skipped.count).to eq(2)
      expect(next_data_import.import_errors.skip_logs.group(:source_object_type).count).to eq(
        'contact' => 1,
        'conversation' => 1,
        'message' => 3
      )
      expect(next_data_import.import_errors.skip_logs.pluck(:details).map { |details| details['reason'] }.uniq).to eq(['already_imported'])
      expect(
        DataImportMapping.where(account: account, source_provider: 'intercom', source_object_type: 'message').distinct.pluck(:data_import_id)
      ).to eq([data_import.id])
    end

    it 'reconciles skipped stats when a superseded run is retried', :aggregate_failures do
      described_class.new(data_import: data_import).perform
      run_id = 'intercom-run-1'
      next_run_id = 'intercom-run-2'
      next_data_import.update!(source_metadata: { DataImport::ACTIVE_INTERCOM_IMPORT_RUN_ID_KEY => run_id })

      importer = described_class.new(data_import: next_data_import, run_id: run_id)
      allow(importer).to receive(:skip_existing_message_mapping).and_wrap_original do |method, *args|
        method.call(*args)
        part = args[2]
        next unless part['id'] == 'part_2'

        DataImport.find(next_data_import.id).update!(source_metadata: { DataImport::ACTIVE_INTERCOM_IMPORT_RUN_ID_KEY => next_run_id })
      end

      importer.import_conversations_page
      expect(next_data_import.reload.stats.dig('messages', 'skipped')).to eq(0)

      retry_importer = described_class.new(data_import: next_data_import, run_id: next_run_id)
      retry_importer.import_conversations_page
      retry_importer.finish!

      expect(next_data_import.reload.stats.dig('conversations', 'skipped')).to eq(1)
      expect(next_data_import.stats.dig('messages', 'skipped')).to eq(3)
      expect(next_data_import.total_records).to eq(5)
    end

    it 'keeps skipped contact stats when a query timeout is retried after the item update', :aggregate_failures do
      described_class.new(data_import: data_import).perform
      importer = described_class.new(data_import: next_data_import)
      contact_log_attempts = 0
      allow(importer).to receive(:sleep)
      allow(importer).to receive(:record_already_imported_log).and_wrap_original do |method, **attributes|
        if attributes[:source_object_type] == 'contact'
          contact_log_attempts += 1
          raise ActiveRecord::QueryCanceled, 'statement timeout' if contact_log_attempts == 1
        end

        method.call(**attributes)
      end

      importer.import_contacts_page

      contact_item = next_data_import.items.find_by!(source_object_type: 'contact', source_object_id: 'contact_1')
      expect(contact_log_attempts).to eq(2)
      expect(importer).to have_received(:sleep).with(be_between(0.2, 0.5)).once
      expect(contact_item).to be_skipped
      expect(next_data_import.reload.stats.dig('contacts', 'skipped')).to eq(1)
      expect(next_data_import.import_errors.skip_logs.exists?(data_import_item: contact_item)).to be(true)
    end

    it 'recreates messages when existing message mappings point to deleted records', :aggregate_failures do
      described_class.new(data_import: data_import).perform
      conversation = account.conversations.find_by!(identifier: 'intercom:conversation_1')
      Message.where(conversation_id: conversation.id).delete_all

      described_class.new(data_import: next_data_import).perform

      expect(conversation.reload.messages.pluck(:source_id)).to match_array(
        %w[
          intercom:conversation:conversation_1:source:source_1
          intercom:conversation:conversation_1:part:part_1
          intercom:conversation:conversation_1:part:part_2
        ]
      )
      expect(next_data_import.reload.stats).to include(
        'contacts' => include('imported' => 0, 'skipped' => 1, 'total' => 1),
        'conversations' => include('imported' => 0, 'skipped' => 1, 'total' => 1),
        'messages' => include('imported' => 3, 'skipped' => 0, 'total' => 3),
        'errors' => { 'count' => 0 }
      )
      expect(next_data_import.import_errors.skip_logs.where(source_object_type: 'message')).to be_empty
      message_mappings = DataImportMapping.where(account: account, source_provider: 'intercom', source_object_type: 'message')
      expect(message_mappings.filter_map(&:chatwoot_record).count).to eq(3)
      expect(message_mappings.distinct.pluck(:data_import_id)).to eq([next_data_import.id])
    end

    it 'repairs a missing mapping without recreating the existing message', :aggregate_failures do
      described_class.new(data_import: data_import).import_conversations_page
      conversation = account.conversations.find_by!(identifier: 'intercom:conversation_1')
      message = conversation.messages.find_by!(source_id: 'intercom:conversation:conversation_1:part:part_1')
      DataImportMapping.find_by!(
        account: account,
        source_provider: 'intercom',
        source_object_type: 'message',
        source_object_id: 'conversation:conversation_1:part:part_1'
      ).destroy!
      importer = described_class.new(data_import: data_import)
      allow(importer).to receive(:find_mapping).and_call_original

      importer.import_conversations_page

      repaired_mapping = DataImportMapping.find_by!(
        account: account,
        source_provider: 'intercom',
        source_object_type: 'message',
        source_object_id: 'conversation:conversation_1:part:part_1'
      )
      expect(conversation.messages.where(source_id: message.source_id).count).to eq(1)
      expect(repaired_mapping.chatwoot_record).to eq(message)
      expect(importer).not_to have_received(:find_mapping).with('message', anything)
      expect(data_import.reload.stats.dig('messages', 'imported')).to eq(3)
    end

    it 'updates conversation activity when a later import adds new messages to the mapped conversation', :aggregate_failures do
      new_part = {
        'id' => 'part_3',
        'part_type' => 'comment',
        'body' => '<p>Follow-up reply</p>',
        'created_at' => 1_700_000_300,
        'updated_at' => 1_700_000_300,
        'author' => { 'type' => 'admin', 'id' => 'admin_1' },
        'attachments' => []
      }
      updated_conversation_payload = conversation_payload.deep_dup
      updated_conversation_payload['updated_at'] = 1_700_000_300
      updated_conversation_payload['conversation_parts']['conversation_parts'] << new_part
      allow(client).to receive(:retrieve_conversation).with('conversation_1').and_return(
        conversation_payload,
        updated_conversation_payload
      )

      described_class.new(data_import: data_import).perform
      conversation = account.conversations.find_by!(identifier: 'intercom:conversation_1')

      described_class.new(data_import: next_data_import).perform

      expect(conversation.reload.last_activity_at).to eq(Time.zone.at(1_700_000_300))
      expect(conversation.messages.find_by!(source_id: 'intercom:conversation:conversation_1:part:part_3').content).to eq('Follow-up reply')
    end
  end

  context 'when a conversation references an already mapped contact' do
    it 'reuses the mapped contact without hydrating the sparse reference' do
      described_class.new(data_import: data_import).import_contacts_page

      expect(client).not_to receive(:retrieve_contact)

      described_class.new(data_import: data_import).import_conversations_page
    end
  end

  context 'when a same-run contact mapping outlives its item progress' do
    let!(:mapped_contact) { create(:contact, account: account) }

    before do
      DataImportMapping.create!(
        account: account,
        data_import: data_import,
        source_provider: 'intercom',
        source_object_type: 'contact',
        source_object_id: 'contact_1',
        chatwoot_record_type: 'Contact',
        chatwoot_record_id: mapped_contact.id,
        metadata: {}
      )
      data_import.items.create!(
        source_provider: 'intercom',
        source_object_type: 'contact',
        source_object_id: 'contact_1',
        status: :processing,
        metadata: contact_payload
      )
    end

    it 'repairs the item and imported count on retry', :aggregate_failures do
      importer = described_class.new(data_import: data_import)
      expect(importer).to receive(:reconcile_item_stats).with('contact').once.ordered.and_call_original
      expect(importer).to receive(:update_cursor).with('contacts', nil).once.ordered.and_call_original

      importer.import_contacts_page

      item = data_import.items.find_by!(source_object_type: 'contact', source_object_id: 'contact_1')
      expect(item).to be_imported
      expect(item).to have_attributes(chatwoot_record_type: 'Contact', chatwoot_record_id: mapped_contact.id)
      expect(data_import.reload.stats.dig('contacts', 'imported')).to eq(1)
    end
  end

  context 'when an existing contact has the same email but a different external id' do
    let(:contact_payload) do
      super().merge('last_replied_at' => 1_700_000_090)
    end
    let!(:existing_contact) { create(:contact, account: account, email: 'customer@example.com', identifier: nil) }

    it 'updates the existing contact instead of creating a duplicate', :aggregate_failures do
      described_class.new(data_import: data_import).import_contacts_page

      expect(existing_contact.reload.identifier).to eq('external_1')
      expect(existing_contact.last_activity_at).to eq(Time.zone.at(1_700_000_090))
      expect(account.contacts.where(email: 'customer@example.com').count).to eq(1)
      item = data_import.items.imported.find_by!(source_object_type: 'contact', source_object_id: 'contact_1')
      expect(item).to have_attributes(chatwoot_record_type: 'Contact', chatwoot_record_id: existing_contact.id)
    end
  end

  context 'when an existing contact has the same phone but a different external id' do
    let(:contact_payload) do
      super().merge('email' => nil)
    end
    let!(:existing_contact) { create(:contact, account: account, phone_number: '+15551234567', identifier: nil) }

    it 'updates the existing contact instead of creating a duplicate', :aggregate_failures do
      described_class.new(data_import: data_import).import_contacts_page

      expect(existing_contact.reload.identifier).to eq('external_1')
      expect(account.contacts.where(phone_number: '+15551234567').count).to eq(1)
      item = data_import.items.imported.find_by!(source_object_type: 'contact', source_object_id: 'contact_1')
      expect(item).to have_attributes(chatwoot_record_type: 'Contact', chatwoot_record_id: existing_contact.id)
    end
  end

  context 'when an existing contact has the same phone but Intercom sends a new email' do
    let!(:existing_contact) { create(:contact, account: account, phone_number: '+15551234567', identifier: nil) }

    it 'falls through to the phone match after the email lookup misses', :aggregate_failures do
      described_class.new(data_import: data_import).import_contacts_page

      expect(existing_contact.reload.email).to eq('customer@example.com')
      expect(existing_contact.identifier).to eq('external_1')
      expect(account.contacts.where(phone_number: '+15551234567').count).to eq(1)
      item = data_import.items.imported.find_by!(source_object_type: 'contact', source_object_id: 'contact_1')
      expect(item).to have_attributes(chatwoot_record_type: 'Contact', chatwoot_record_id: existing_contact.id)
    end
  end

  context 'when an existing visitor contact matches the Intercom external id' do
    let!(:existing_contact) { create(:contact, account: account, identifier: 'external_1') }

    it 'promotes the contact to a lead when adding email or phone', :aggregate_failures do
      expect(existing_contact).to be_visitor

      described_class.new(data_import: data_import).import_contacts_page

      expect(existing_contact.reload).to be_lead
      expect(existing_contact.email).to eq('customer@example.com')
      expect(existing_contact.phone_number).to eq('+15551234567')
    end
  end

  context 'when an identifier match has contact details owned by another contact' do
    let!(:existing_contact) { create(:contact, account: account, identifier: 'external_1') }
    let!(:email_owner) { create(:contact, account: account, email: 'customer@example.com') }
    let!(:phone_owner) { create(:contact, account: account, phone_number: '+15551234567') }

    it 'does not copy the conflicting email or phone number', :aggregate_failures do
      described_class.new(data_import: data_import).import_contacts_page

      expect(existing_contact.reload.email).to be_nil
      expect(existing_contact.phone_number).to be_nil
      expect(existing_contact).to be_visitor
      expect(email_owner.reload.email).to eq('customer@example.com')
      expect(phone_owner.reload.phone_number).to eq('+15551234567')
      expect(account.contacts.where(email: 'customer@example.com').count).to eq(1)
      expect(account.contacts.where(phone_number: '+15551234567').count).to eq(1)

      item = data_import.items.imported.find_by!(source_object_type: 'contact', source_object_id: 'contact_1')
      expect(item).to have_attributes(chatwoot_record_type: 'Contact', chatwoot_record_id: existing_contact.id)
    end
  end

  context 'when Intercom rate limits a conversation detail request' do
    before do
      allow(client).to receive(:retrieve_conversation).with('conversation_1').and_raise(
        DataImports::Intercom::Client::RateLimitError.new('rate limited', status: 429)
      )
    end

    it 're-raises the provider error so the page job can retry', :aggregate_failures do
      expect { described_class.new(data_import: data_import).import_conversations_page }
        .to raise_error(DataImports::Intercom::Client::RateLimitError)

      item = data_import.items.find_by!(source_object_type: 'conversation', source_object_id: 'conversation_1')
      expect(item).to be_processing
      expect(data_import.import_errors.exists?).to be(false)
    end
  end

  context 'when Intercom rate limits a contact hydration request' do
    before do
      allow(client).to receive(:retrieve_contact).with('contact_1').and_raise(
        DataImports::Intercom::Client::RateLimitError.new('rate limited', status: 429)
      )
    end

    it 're-raises the provider error instead of importing a sparse contact', :aggregate_failures do
      expect { described_class.new(data_import: data_import).import_conversations_page }
        .to raise_error(DataImports::Intercom::Client::RateLimitError)

      expect(data_import.items.exists?(source_object_type: 'contact')).to be(false)
      expect(data_import.import_errors.exists?).to be(false)
    end
  end

  context 'when Intercom no longer has a sparse contact referenced by a conversation' do
    before do
      allow(client).to receive(:retrieve_contact).with('contact_1').and_raise(
        DataImports::Intercom::Client::Error.new('not found', status: 404)
      )
    end

    it 'falls back to the conversation contact reference', :aggregate_failures do
      expect { described_class.new(data_import: data_import).import_conversations_page }.not_to raise_error

      expect(data_import.items.imported.exists?(source_object_type: 'contact', source_object_id: 'contact_1')).to be(true)
      expect(data_import.import_errors.exists?).to be(false)
    end
  end

  context 'when the Intercom source message only has attachments' do
    let(:conversation_payload) do
      super().deep_merge(
        'source' => {
          'subject' => nil,
          'body' => nil,
          'attachments' => [{ 'name' => 'invoice.pdf', 'url' => 'https://example.com/invoice.pdf' }]
        },
        'conversation_parts' => {
          'conversation_parts' => []
        }
      )
    end

    it 'imports the source message attachment placeholder', :aggregate_failures do
      described_class.new(data_import: data_import).perform

      conversation = account.conversations.find_by!(identifier: 'intercom:conversation_1')
      expect(conversation.messages.pluck(:content)).to eq(['[Intercom attachment skipped: 1]'])
      expect(conversation.messages.first.additional_attributes.dig('source', 'attachments')).to eq(
        [{ 'name' => 'invoice.pdf', 'url' => 'https://example.com/invoice.pdf' }]
      )
      expect(data_import.reload.stats.dig('messages', 'imported')).to eq(1)
    end
  end

  context 'when the Intercom source message has text and attachments' do
    let(:conversation_payload) do
      super().deep_merge(
        'source' => {
          'attachments' => [{ 'name' => 'invoice.pdf', 'url' => 'https://example.com/invoice.pdf' }]
        }
      )
    end

    it 'adds an attachment omission marker to the imported message', :aggregate_failures do
      described_class.new(data_import: data_import).perform

      message = account.messages.find_by!(source_id: 'intercom:conversation:conversation_1:source:source_1')
      expect(message.content).to eq("Need help\n\nHello there\n\n[Intercom attachment skipped: 1]")
      expect(message.additional_attributes.dig('source', 'attachments')).to eq(
        [{ 'name' => 'invoice.pdf', 'url' => 'https://example.com/invoice.pdf' }]
      )
      expect(data_import.reload.stats.dig('messages', 'skipped')).to eq(0)
    end
  end

  context 'when Intercom omits the conversation source' do
    let(:conversation_payload) do
      super().merge(
        'source' => nil,
        'first_contact_reply' => {
          'type' => 'whatsapp',
          'created_at' => 1_700_000_000,
          'url' => nil
        }
      )
    end

    it 'routes the conversation from the first contact reply type', :aggregate_failures do
      described_class.new(data_import: data_import).perform

      inbox = account.inboxes.find_by!(name: 'Intercom Import - WhatsApp')
      conversation = account.conversations.find_by!(identifier: 'intercom:conversation_1')

      expect(conversation.inbox).to eq(inbox)
      expect(conversation.additional_attributes.dig('source', 'source_type')).to eq('whatsapp')
    end
  end

  context 'when an Intercom chat message part cannot be imported' do
    let(:conversation_payload) do
      super().deep_merge(
        'conversation_parts' => {
          'conversation_parts' => [
            {
              'id' => 'blank_part',
              'part_type' => 'comment',
              'body' => nil,
              'created_at' => 1_700_000_175,
              'updated_at' => 1_700_000_175,
              'author' => { 'type' => 'admin', 'id' => 'admin_1' },
              'attachments' => []
            }
          ]
        }
      )
    end

    it 'records a skip log with the Intercom message source id', :aggregate_failures do
      described_class.new(data_import: data_import).perform

      skip_log = data_import.import_errors.skip_logs.find_by!(source_object_type: 'message')
      expect(skip_log).to have_attributes(
        source_object_id: 'conversation:conversation_1:part:blank_part',
        error_code: 'DataImports::Intercom::SkippedMessage',
        message: 'Skipped Intercom comment event blank_part: no message body or attachments to import.'
      )
      expect(skip_log.details).to include(
        'kind' => 'skipped',
        'reason' => 'blank_or_unsupported_intercom_part',
        'reason_details' => 'no message body or attachments to import',
        'event_name' => 'comment',
        'event_type' => 'comment',
        'author_type' => 'admin'
      )
      expect(data_import.reload.stats.dig('messages', 'skipped')).to eq(1)
    end

    it 'retries skip-log reconciliation after a query timeout', :aggregate_failures do
      importer = described_class.new(data_import: data_import)
      attempts = 0
      allow(importer).to receive(:sleep)
      allow(importer).to receive(:record_skipped_message_log).and_wrap_original do |method, *args|
        attempts += 1
        raise ActiveRecord::QueryCanceled, 'statement timeout' if attempts == 1

        method.call(*args)
      end

      importer.perform

      expect(attempts).to eq(2)
      expect(importer).to have_received(:sleep).with(be_between(0.2, 0.5)).once
      expect(data_import.reload).to be_completed
      expect(data_import.stats.dig('messages', 'skipped')).to eq(1)
    end

    it 'isolates a persistent skip-log reconciliation failure to the message', :aggregate_failures do
      importer = described_class.new(data_import: data_import)
      allow(importer).to receive(:record_skipped_message_log).and_raise(ActiveRecord::StatementInvalid, 'skip log failed')

      importer.perform

      item = data_import.items.find_by!(source_object_type: 'conversation', source_object_id: 'conversation_1')
      error = data_import.import_errors.find_by!(
        source_object_type: 'message',
        source_object_id: 'conversation:conversation_1:part:blank_part'
      )
      expect(item).to be_imported
      expect(error).to have_attributes(error_code: 'ActiveRecord::StatementInvalid', message: 'skip log failed')
      expect(data_import.reload).to be_completed_with_errors
      expect(data_import.stats.dig('errors', 'count')).to eq(1)
    end

    it 'records the skip log again for a later import run', :aggregate_failures do
      described_class.new(data_import: data_import).perform
      next_data_import = create(
        :data_import, :intercom,
        account: account
      )

      described_class.new(data_import: next_data_import).perform

      skip_log = next_data_import.import_errors.skip_logs.find_by!(
        source_object_type: 'message',
        source_object_id: 'conversation:conversation_1:part:blank_part',
        error_code: 'DataImports::Intercom::SkippedMessage'
      )
      expect(skip_log).to have_attributes(
        source_object_id: 'conversation:conversation_1:part:blank_part',
        error_code: 'DataImports::Intercom::SkippedMessage'
      )
      expect(next_data_import.reload.stats.dig('messages', 'skipped')).to eq(2)
    end

    it 'reconciles a same-run skipped mapping and missing skip log on retry', :aggregate_failures do
      described_class.new(data_import: data_import).import_conversations_page
      data_import.import_errors.where(source_object_type: 'message').delete_all
      stats = data_import.reload.stats.deep_dup
      stats['messages']['skipped'] = 0
      data_import.update!(stats: stats)

      described_class.new(data_import: data_import).import_conversations_page

      expect(data_import.reload.stats.dig('messages', 'skipped')).to eq(1)
      expect(data_import.import_errors.skip_logs.exists?(source_object_id: 'conversation:conversation_1:part:blank_part')).to be(true)
    end

    it 'repairs a previously skipped mapping when the part is now an activity', :aggregate_failures do
      described_class.new(data_import: data_import).perform
      previous_skip_log = data_import.import_errors.skip_logs.find_by!(source_object_id: 'conversation:conversation_1:part:blank_part')
      conversation_payload.dig('conversation_parts', 'conversation_parts').first.merge!(
        'part_type' => 'assignment',
        'assigned_to' => { 'name' => 'Support' }
      )
      next_data_import = create(:data_import, :intercom, account: account)

      described_class.new(data_import: next_data_import).perform

      activity = account.messages.find_by!(source_id: 'intercom:conversation:conversation_1:part:blank_part')
      mapping = DataImportMapping.find_by!(
        account: account,
        source_provider: 'intercom',
        source_object_type: 'message',
        source_object_id: 'conversation:conversation_1:part:blank_part'
      )
      expect(activity).to be_activity
      expect(activity.content).to eq('Intercom teammate assigned the conversation to Support')
      expect(mapping.chatwoot_record).to eq(activity)
      expect(data_import.import_errors.skip_logs).to include(previous_skip_log)
      expect(next_data_import.import_errors.skip_logs.where(source_object_id: mapping.source_object_id)).to be_empty
    end
  end

  context 'when Intercom returns bodyless lifecycle events' do
    let(:conversation_payload) do
      super().deep_merge(
        'conversation_parts' => {
          'total_count' => 1,
          'conversation_parts' => [
            {
              'id' => 'assignment_part',
              'part_type' => 'assignment',
              'body' => nil,
              'created_at' => 1_700_000_175,
              'author' => { 'type' => 'admin', 'name' => 'Avery' },
              'assigned_to' => { 'type' => 'team', 'name' => 'Support' },
              'state' => 'open',
              'tags' => { 'tags' => [{ 'name' => 'priority' }] },
              'event_details' => { 'source' => 'workflow' },
              'app_package_code' => 'workflow'
            }
          ]
        }
      )
    end

    it 'imports events as public activity messages with source metadata', :aggregate_failures do
      described_class.new(data_import: data_import).perform

      activity = account.messages.find_by!(source_id: 'intercom:conversation:conversation_1:part:assignment_part')
      expect(activity).to have_attributes(
        message_type: 'activity',
        content: 'Avery assigned the conversation to Support',
        private: false,
        sender: nil,
        created_at: Time.zone.at(1_700_000_175)
      )
      expect(activity.additional_attributes['source']).to include(
        'part_type' => 'assignment',
        'assigned_to' => include('name' => 'Support'),
        'state' => 'open',
        'event_details' => include('source' => 'workflow'),
        'app_package_code' => 'workflow'
      )
      expect(data_import.reload.stats['messages']).to include('imported' => 2, 'skipped' => 0, 'total' => 2)
      expect(data_import.import_errors.skip_logs).to be_empty
    end
  end

  context 'when Intercom omits older conversation parts from the retrieved conversation' do
    let(:conversation_payload) do
      super().deep_merge(
        'conversation_parts' => {
          'total_count' => 503
        },
        'statistics' => {
          'count_conversation_parts' => 503
        }
      )
    end

    it 'records an incomplete import error and completes with errors', :aggregate_failures do
      described_class.new(data_import: data_import).perform

      error = data_import.import_errors.non_skip_logs.find_by!(
        source_object_type: 'conversation',
        source_object_id: 'conversation_1',
        error_code: 'DataImports::Intercom::TruncatedConversationParts'
      )
      expect(error.message).to eq('Intercom returned 2 of 503 conversation parts.')
      expect(error.details).to include(
        'kind' => 'incomplete',
        'imported_parts_count' => 2,
        'total_parts_count' => 503
      )
      expect(data_import.reload).to be_completed_with_errors
      expect(data_import.stats.dig('errors', 'count')).to eq(1)
    end

    it 'reconciles error stats when a superseded run is retried', :aggregate_failures do
      run_id = 'intercom-run-1'
      next_run_id = 'intercom-run-2'
      data_import.update!(source_metadata: { DataImport::ACTIVE_INTERCOM_IMPORT_RUN_ID_KEY => run_id })
      importer = described_class.new(data_import: data_import, run_id: run_id)
      allow(importer).to receive(:bulk_write_message_entries).and_wrap_original do |method, *args|
        method.call(*args).tap do
          DataImport.find(data_import.id).update!(source_metadata: { DataImport::ACTIVE_INTERCOM_IMPORT_RUN_ID_KEY => next_run_id })
        end
      end

      importer.import_conversations_page
      expect(data_import.reload.stats.dig('errors', 'count')).to eq(0)

      retry_importer = described_class.new(data_import: data_import, run_id: next_run_id)
      retry_importer.import_conversations_page
      retry_importer.finish!

      expect(data_import.reload).to be_completed_with_errors
      expect(data_import.stats.dig('errors', 'count')).to eq(1)
      expect(data_import.total_records).to eq(6)
    end
  end

  context 'when the conversation parts total matches the returned parts' do
    let(:conversation_payload) do
      super().deep_merge(
        'conversation_parts' => {
          'total_count' => 2
        },
        'statistics' => {
          'count_conversation_parts' => 2
        }
      )
    end

    it 'does not record a truncated parts error', :aggregate_failures do
      described_class.new(data_import: data_import).perform

      expect(data_import.import_errors.non_skip_logs).to be_empty
      expect(data_import.reload).to be_completed
      expect(data_import.stats.dig('errors', 'count')).to eq(0)
    end
  end

  context 'when Intercom statistics count is higher than the conversation parts total' do
    let(:conversation_payload) do
      super().deep_merge(
        'source' => {},
        'conversation_parts' => {
          'total_count' => 2
        },
        'statistics' => {
          'count_conversation_parts' => 3
        }
      )
    end

    it 'trusts the returned conversation parts total over the statistics counter', :aggregate_failures do
      described_class.new(data_import: data_import).perform

      expect(data_import.import_errors.non_skip_logs).to be_empty
      expect(data_import.reload).to be_completed
      expect(data_import.stats.dig('errors', 'count')).to eq(0)
    end
  end

  context 'when a specific Intercom message part fails to persist' do
    let(:insert_attempts) { [] }

    let(:conversation_payload) do
      super().deep_merge(
        'conversation_parts' => {
          'conversation_parts' => [
            {
              'id' => 'bad_part',
              'part_type' => 'comment',
              'body' => '<p>Message that cannot be stored</p>',
              'created_at' => 1_700_000_175,
              'updated_at' => 1_700_000_175,
              'author' => { 'type' => 'admin', 'id' => 'admin_1' },
              'attachments' => []
            }
          ]
        }
      )
    end

    before do
      allow(Message).to receive(:insert_all!).and_wrap_original do |method, records, **kwargs|
        if records.any? { |record| record[:source_id] == 'intercom:conversation:conversation_1:part:bad_part' }
          insert_attempts << 'intercom:conversation:conversation_1:part:bad_part'
          raise ActiveRecord::StatementInvalid, 'bad message'
        end

        method.call(records, **kwargs)
      end
    end

    it 'records a skip log with the Intercom message part id', :aggregate_failures do
      described_class.new(data_import: data_import).perform

      skip_log = data_import.import_errors.skip_logs.find_by!(source_object_type: 'message')
      expect(skip_log).to have_attributes(
        source_object_id: 'conversation:conversation_1:part:bad_part',
        error_code: 'ActiveRecord::StatementInvalid',
        message: 'bad message'
      )
      expect(skip_log.details).to include(
        'kind' => 'failed',
        'conversation_id' => 'intercom:conversation_1'
      )
      expect(data_import.reload).to be_completed_with_errors
      expect(data_import.stats.dig('errors', 'count')).to eq(1)
      expect(insert_attempts.size).to eq(2)
      expect(data_import.import_errors.where(source_object_type: 'message').count).to eq(1)
      expect(account.messages.find_by(source_id: 'intercom:conversation:conversation_1:source:source_1')).to be_present
    end
  end
end
