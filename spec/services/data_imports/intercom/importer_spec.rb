require 'rails_helper'

RSpec.describe DataImports::Intercom::Importer do
  let(:account) { create(:account) }
  let(:hook) { create(:integrations_hook, :intercom, account: account, access_token: 'intercom-token') }
  let(:data_import) do
    create(
      :data_import,
      account: account,
      data_type: 'intercom',
      source_type: 'integration',
      source_provider: 'intercom',
      import_types: %w[contacts conversations],
      integration_hook: hook,
      import_file: nil
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
    allow(client).to receive(:list_contacts).with(starting_after: nil).and_return(
      'data' => [contact_payload],
      'pages' => { 'next' => nil }
    )
    allow(client).to receive(:list_conversations).with(starting_after: nil).and_return(
      'conversations' => [{ 'id' => 'conversation_1' }],
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
      'contacts' => { 'imported' => 1, 'skipped' => 0 },
      'conversations' => { 'imported' => 1, 'skipped' => 0 },
      'messages' => { 'imported' => 3, 'skipped' => 0 },
      'errors' => { 'count' => 0 }
    )
    expect(data_import.processed_records).to eq(5)
    expect(data_import.items.imported.count).to eq(2)
    expect(DataImportMapping.where(data_import: data_import).count).to eq(5)
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

  it 'indexes imported messages for advanced search' do
    allow(ChatwootApp).to receive(:advanced_search_allowed?).and_return(true)
    allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(false)
    reindexed_message_ids = []
    original_reindex_for_search = Message.instance_method(:reindex_for_search)
    Message.define_method(:reindex_for_search) { reindexed_message_ids << id }
    Message.__send__(:private, :reindex_for_search)

    described_class.new(data_import: data_import).perform

    expect(reindexed_message_ids).to match_array(Message.where(account_id: account.id).pluck(:id))
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
      allow(client).to receive(:list_conversations).with(starting_after: nil).and_return(
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

    it 'rolls back a newly inserted message when mapping persistence fails', :aggregate_failures do
      importer = described_class.new(data_import: data_import)
      allow(importer).to receive(:record_mapping).and_wrap_original do |method, object_type, source_id, record, metadata:|
        raise StandardError, 'mapping failed' if object_type == 'message'

        method.call(object_type, source_id, record, metadata: metadata)
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
  end

  context 'when the Intercom records were imported by an earlier run' do
    let(:next_data_import) do
      create(
        :data_import,
        account: account,
        data_type: 'intercom',
        source_type: 'integration',
        source_provider: 'intercom',
        import_types: %w[contacts conversations],
        integration_hook: hook,
        import_file: nil
      )
    end

    it 'records the already mapped records as skipped for the current import run', :aggregate_failures do
      described_class.new(data_import: data_import).perform

      described_class.new(data_import: next_data_import).perform

      expect(next_data_import.reload.stats).to include(
        'contacts' => { 'imported' => 0, 'skipped' => 1 },
        'conversations' => { 'imported' => 0, 'skipped' => 1 },
        'messages' => { 'imported' => 0, 'skipped' => 3 },
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
        'contacts' => { 'imported' => 0, 'skipped' => 1 },
        'conversations' => { 'imported' => 0, 'skipped' => 1 },
        'messages' => { 'imported' => 3, 'skipped' => 0 },
        'errors' => { 'count' => 0 }
      )
      expect(next_data_import.import_errors.skip_logs.where(source_object_type: 'message')).to be_empty
      message_mappings = DataImportMapping.where(account: account, source_provider: 'intercom', source_object_type: 'message')
      expect(message_mappings.filter_map(&:chatwoot_record).count).to eq(3)
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

  context 'when an Intercom message part cannot be imported' do
    let(:conversation_payload) do
      super().deep_merge(
        'conversation_parts' => {
          'conversation_parts' => [
            {
              'id' => 'blank_part',
              'part_type' => 'assignment',
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
        message: 'Skipped Intercom assignment event blank_part: no message body or attachments to import.'
      )
      expect(skip_log.details).to include(
        'kind' => 'skipped',
        'reason' => 'blank_or_unsupported_intercom_part',
        'reason_details' => 'no message body or attachments to import',
        'event_name' => 'assignment',
        'event_type' => 'assignment',
        'author_type' => 'admin'
      )
      expect(data_import.reload.stats.dig('messages', 'skipped')).to eq(1)
    end

    it 'records the skip log again for a later import run', :aggregate_failures do
      described_class.new(data_import: data_import).perform
      next_data_import = create(
        :data_import,
        account: account,
        data_type: 'intercom',
        source_type: 'integration',
        source_provider: 'intercom',
        import_types: %w[contacts conversations],
        integration_hook: hook,
        import_file: nil
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
      expect(error.message).to eq('Intercom returned 3 of 503 conversation parts.')
      expect(error.details).to include(
        'kind' => 'incomplete',
        'imported_parts_count' => 3,
        'total_parts_count' => 503
      )
      expect(data_import.reload).to be_completed_with_errors
      expect(data_import.stats.dig('errors', 'count')).to eq(1)
    end
  end

  context 'when Intercom includes the root source message in the conversation parts total' do
    let(:conversation_payload) do
      super().deep_merge(
        'conversation_parts' => {
          'total_count' => 3
        },
        'statistics' => {
          'count_conversation_parts' => 3
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
        raise ActiveRecord::StatementInvalid, 'bad message' if records.first[:source_id] == 'intercom:conversation:conversation_1:part:bad_part'

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
    end
  end
end
