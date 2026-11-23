require 'rails_helper'

RSpec.describe Whatsapp::IncomingCallBroadcast do
  let(:account) { create(:account) }
  let(:inbox) { create(:channel_whatsapp, account: account, sync_templates: false, validate_provider_config: false).inbox }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:agent) { create(:user, account: account) }
  let(:other_agent) { create(:user, account: account) }
  let(:call) do
    create(:call, account: account, inbox: inbox, conversation: conversation, contact: conversation.contact,
                  provider: :whatsapp, direction: :incoming, status: 'ringing', provider_call_id: 'wacid_1',
                  meta: { 'sdp_offer' => "v=0\r\n" })
  end

  before { allow(ActionCable.server).to receive(:broadcast) }

  it 'sends the call and its offer to the given agents only' do
    described_class.new(call: call, user_ids: [agent.id]).perform

    expect(ActionCable.server).to have_received(:broadcast).with(
      agent.pubsub_token,
      { event: 'voice_call.incoming',
        data: hash_including(account_id: account.id, id: call.id, call_id: 'wacid_1', provider: 'whatsapp',
                             conversation_id: conversation.id, inbox_id: inbox.id, sdp_offer: "v=0\r\n") }
    )
    expect(ActionCable.server).not_to have_received(:broadcast).with(other_agent.pubsub_token, anything)
  end

  it 'sends nothing once the call has stopped ringing' do
    call.update!(status: 'no_answer')

    described_class.new(call: call, user_ids: [agent.id]).perform

    expect(ActionCable.server).not_to have_received(:broadcast)
  end
end
