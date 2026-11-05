require 'rails_helper'

RSpec.describe ActionCableBroadcastJob do
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account) }
  let(:stale_data) { { id: conversation.display_id, account_id: account.id, status: 'open' } }

  before do
    conversation.update!(status: :resolved)
    allow(ActionCable.server).to receive(:broadcast)
  end

  it 'refreshes a conversation event with the full payload for agents' do
    described_class.perform_now(['agent-token'], Events::Types::CONVERSATION_STATUS_CHANGED, stale_data)

    expect(ActionCable.server).to have_received(:broadcast).with(
      'agent-token',
      { event: Events::Types::CONVERSATION_STATUS_CHANGED, data: conversation.reload.push_event_data.merge(account_id: account.id) }
    )
  end

  it 'refreshes a conversation event with the widget payload for widget sessions' do
    described_class.perform_now(['widget-token'], Events::Types::CONVERSATION_STATUS_CHANGED, stale_data, widget: true)

    expect(ActionCable.server).to have_received(:broadcast).with(
      'widget-token',
      { event: Events::Types::CONVERSATION_STATUS_CHANGED, data: conversation.reload.widget_push_event_data.merge(account_id: account.id) }
    )
  end
end
