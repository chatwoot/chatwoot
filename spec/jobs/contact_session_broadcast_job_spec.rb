require 'rails_helper'

RSpec.describe ContactSessionBroadcastJob do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account) }
  let(:conversation) { create(:conversation, account: account, assignee: agent) }
  let(:members) { [conversation.contact_inbox.pubsub_token] }
  let(:data) do
    Conversations::EventDataPresenter.contact_slice(conversation.push_event_data).merge(account_id: account.id)
  end

  before { create(:message, conversation: conversation, account: account, message_type: :outgoing, sender: agent) }

  # The parent's refresh rebuilds the messages from the conversation, and each embeds the assignee (#1001).
  it 'refreshes the conversation without handing the session the assignee back' do
    payloads = []
    allow(ActionCable.server).to receive(:broadcast) { |_member, payload| payloads << payload }

    described_class.new.perform(members, 'conversation.status_changed', data)

    refreshed = payloads.sole[:data]
    expect(refreshed[:status]).to eq(conversation.status)
    expect(refreshed[:messages].first[:conversation]).not_to have_key(:assignee_id)
    expect(refreshed[:account_id]).to eq(account.id)
  end

  it 'leaves out the assignment the parent adds to an assignee change' do
    payloads = []
    allow(ActionCable.server).to receive(:broadcast) { |_member, payload| payloads << payload }

    described_class.new.perform(members, 'assignee.changed', data)

    expect(payloads.sole[:data]).not_to have_key(:assignment)
  end
end
