require 'rails_helper'

RSpec.describe SalesRouting::SyncAssignmentsJob do
  let(:conversation) { create(:conversation) }
  let(:event) do
    ConversationAssignmentEvent.create!(account: conversation.account, conversation: conversation, inbox_id: conversation.inbox_id,
                                        conversation_display_id: conversation.display_id, agent_id: 42, agent_name: 'Seller',
                                        source: 'automatic', event_kind: 'initial', assigned_at: Time.iso8601('2026-10-13T01:00:00Z'))
  end
  let(:connection) { instance_double(PG::Connection, exec: nil, exec_params: nil) }

  it 'preserves the legacy display-ID contract, Sao Paulo date and a stable retry key' do
    event
    allow(PG).to receive(:connect).and_yield(connection)
    expect(connection).to receive(:exec_params).with(include('ON CONFLICT (event_key) DO NOTHING'),
                                                     ["chatwoot:#{event.account_id}:assignment:#{event.id}", 42, 'Seller', conversation.display_id,
                                                      '2026-10-13T01:00:00.000000Z', '2026-10-12', event.account_id, event.inbox_id,
                                                      conversation.id, 'initial', 'automatic', nil, '{}'])
    with_modified_env HERMES_DISTRIBUTION_DATABASE_URL: 'postgresql://test.invalid/hermes' do
      described_class.perform_now
    end
    expect(event.reload.synced_at).to be_present
  end

  it 'keeps the committed event pending after a reporting-database outage' do
    event
    allow(PG).to receive(:connect).and_raise(PG::ConnectionBad)
    with_modified_env HERMES_DISTRIBUTION_DATABASE_URL: 'postgresql://test.invalid/hermes' do
      expect { described_class.new.perform }.to raise_error(PG::ConnectionBad)
    end
    expect(event.reload.synced_at).to be_nil
  end
end
