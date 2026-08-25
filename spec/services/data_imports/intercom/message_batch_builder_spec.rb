require 'rails_helper'

RSpec.describe DataImports::Intercom::MessageBatchBuilder do
  let(:account) { create(:account) }
  let(:data_import) { create(:data_import, :intercom, account: account) }
  let(:conversation) { create(:conversation, account: account) }
  let(:source_conversation) do
    {
      'id' => 'conversation_1',
      'created_at' => 1_700_000_000,
      'source' => {
        'id' => 'source_1',
        'part_type' => 'conversation',
        'body' => '<p>Initial message</p>',
        'created_at' => 1_700_000_000
      },
      'conversation_parts' => {
        'conversation_parts' => [
          {
            'id' => 'part_1',
            'part_type' => 'comment',
            'body' => '<p>First reply</p>',
            'created_at' => 1_700_000_000
          },
          {
            'id' => 'part_2',
            'part_type' => 'note',
            'body' => '<p>Internal note</p>',
            'created_at' => 1_700_000_100
          }
        ]
      }
    }
  end
  let(:builder) do
    described_class.new(
      data_import: data_import,
      conversation: conversation,
      source_conversation: source_conversation
    )
  end

  it 'preserves source order and prefetches mappings and messages once per batch', :aggregate_failures do
    sql_queries = []
    subscriber = lambda do |_name, _start, _finish, _id, payload|
      sql_queries << payload unless payload[:name] == 'SCHEMA'
    end
    batch_builder = builder

    batch = ActiveSupport::Notifications.subscribed(subscriber, 'sql.active_record') { batch_builder.perform }

    expect(batch.entries.map(&:source_id)).to eq(
      %w[
        conversation:conversation_1:source:source_1
        conversation:conversation_1:part:part_1
        conversation:conversation_1:part:part_2
      ]
    )
    expect(batch.entries.map(&:position)).to eq([0, 1, 2])
    expect(batch.entries.map(&:classification)).to all(eq(:new_message))
    expect(sql_queries.count { |query| query[:name] == 'DataImportMapping Load' }).to eq(1)
    message_queries = sql_queries.select { |query| query[:name] == 'Message Load' }
    expect(message_queries.size).to eq(1), message_queries.pluck(:sql).join("\n")
  end

  it 'returns an empty batch without prefetch queries when the conversation has no messages' do
    source_conversation['source'] = nil
    source_conversation['conversation_parts']['conversation_parts'] = []

    expect(DataImportMapping).not_to receive(:where)
    expect(Message).not_to receive(:where)

    expect(builder.perform.entries).to be_empty
  end

  it 'refreshes classifications while preserving source positions' do
    batch = builder.perform
    target_entry = batch.entries.second
    message = create(
      :message,
      account: account,
      conversation: conversation,
      inbox: conversation.inbox,
      source_id: "intercom:#{target_entry.source_id}"
    )
    DataImportMapping.create!(
      account: account,
      data_import: data_import,
      source_provider: 'intercom',
      source_object_type: 'message',
      source_object_id: target_entry.source_id,
      chatwoot_record_type: 'Message',
      chatwoot_record_id: message.id,
      metadata: {}
    )

    refreshed_batch = builder.refresh(batch.entries)

    expect(refreshed_batch.entries.map(&:position)).to eq([0, 1, 2])
    expect(refreshed_batch.entries.second).to have_attributes(classification: :current_import, message: message)
  end

  it 'classifies a live mapping from the current import as already handled' do
    message = create(
      :message,
      account: account,
      conversation: conversation,
      inbox: conversation.inbox,
      source_id: 'intercom:conversation:conversation_1:part:part_1'
    )
    DataImportMapping.create!(
      account: account,
      data_import: data_import,
      source_provider: 'intercom',
      source_object_type: 'message',
      source_object_id: 'conversation:conversation_1:part:part_1',
      chatwoot_record_type: 'Message',
      chatwoot_record_id: message.id,
      metadata: {}
    )

    entry = builder.perform.entries.find { |batch_entry| batch_entry.source_id.end_with?('part:part_1') }

    expect(entry).to have_attributes(classification: :current_import, message: message)
  end

  it 'classifies a live mapping from a previous import without changing its owner' do
    previous_import = create(:data_import, :intercom, account: account)
    message = create(
      :message,
      account: account,
      conversation: conversation,
      inbox: conversation.inbox,
      source_id: 'intercom:conversation:conversation_1:part:part_1'
    )
    mapping = DataImportMapping.create!(
      account: account,
      data_import: previous_import,
      source_provider: 'intercom',
      source_object_type: 'message',
      source_object_id: 'conversation:conversation_1:part:part_1',
      chatwoot_record_type: 'Message',
      chatwoot_record_id: message.id,
      metadata: {}
    )

    entry = builder.perform.entries.find { |batch_entry| batch_entry.source_id.end_with?('part:part_1') }

    expect(entry).to have_attributes(classification: :previous_import, mapping: mapping, message: message)
    expect(mapping.reload.data_import).to eq(previous_import)
  end

  it 'classifies a mapping whose message was deleted as repairable' do
    mapping = DataImportMapping.create!(
      account: account,
      data_import: data_import,
      source_provider: 'intercom',
      source_object_type: 'message',
      source_object_id: 'conversation:conversation_1:part:part_1',
      chatwoot_record_type: 'Message',
      chatwoot_record_id: 0,
      metadata: {}
    )

    entry = builder.perform.entries.find { |batch_entry| batch_entry.source_id.end_with?('part:part_1') }

    expect(entry).to have_attributes(classification: :repairable_stale_mapping, mapping: mapping, message: nil)
  end

  it 'classifies an existing conversation message without a mapping for repair' do
    message = create(
      :message,
      account: account,
      conversation: conversation,
      inbox: conversation.inbox,
      source_id: 'intercom:conversation:conversation_1:part:part_1'
    )

    entry = builder.perform.entries.find { |batch_entry| batch_entry.source_id.end_with?('part:part_1') }

    expect(entry).to have_attributes(classification: :existing_message, mapping: nil, message: message)
  end

  it 'repairs a skipped mapping when the source part is now an activity' do
    source_conversation.dig('conversation_parts', 'conversation_parts').first.merge!(
      'part_type' => 'assignment',
      'body' => nil,
      'assigned_to' => { 'name' => 'Support' }
    )
    mapping = DataImportMapping.create!(
      account: account,
      data_import: data_import,
      source_provider: 'intercom',
      source_object_type: 'message',
      source_object_id: 'conversation:conversation_1:part:part_1',
      chatwoot_record_type: 'Conversation',
      chatwoot_record_id: conversation.id,
      metadata: { skipped: true }
    )

    entry = builder.perform.entries.find { |batch_entry| batch_entry.source_id.end_with?('part:part_1') }

    expect(entry).to have_attributes(classification: :repairable_stale_mapping, mapping: mapping, message: nil)
  end
end
