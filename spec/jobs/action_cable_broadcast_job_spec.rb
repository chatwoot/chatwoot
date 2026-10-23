require 'rails_helper'

RSpec.describe ActionCableBroadcastJob do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account) }
  let(:conversation) { create(:conversation, account: account) }

  before do
    create(:inbox_member, user: agent, inbox: conversation.inbox)
    allow(ActionCable.server).to receive(:broadcast)
  end

  it 'refreshes an agent update with the current participant and mentioned user ids' do
    data = conversation.dashboard_push_event_data.merge(account_id: account.id)
    create(:conversation_participant, conversation: conversation, account: account, user: agent)

    described_class.perform_now([agent.pubsub_token], Events::Types::CONVERSATION_UPDATED, data)

    expect(ActionCable.server).to have_received(:broadcast)
      .with(agent.pubsub_token, hash_including(data: hash_including(participant_ids: [agent.id], mentioned_user_ids: [])))
  end

  it 'refreshes a contact update without the participant and mentioned user ids' do
    contact_token = conversation.contact_inbox.pubsub_token
    data = conversation.push_event_data.merge(account_id: account.id)

    described_class.perform_now([contact_token], Events::Types::CONVERSATION_UPDATED, data)

    expect(ActionCable.server).to have_received(:broadcast)
      .with(contact_token, hash_including(data: hash_excluding(:participant_ids, :mentioned_user_ids)))
  end
end
