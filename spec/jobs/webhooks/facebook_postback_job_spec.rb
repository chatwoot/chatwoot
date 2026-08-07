require 'rails_helper'

describe Webhooks::FacebookPostbackJob do
  before do
    allow(Facebook::Messenger::Subscriptions).to receive(:subscribe).and_return(true)
  end

  let!(:account1) { create(:account) }
  let!(:account2) { create(:account) }
  # The same Facebook page can be connected to more than one Chatwoot account.
  let!(:facebook_channel1) { create(:channel_facebook_page, account: account1, page_id: 'shared_page_id') }
  let!(:facebook_channel2) { create(:channel_facebook_page, account: account2, page_id: 'shared_page_id') }
  let(:facebook_inbox1) { facebook_channel1.inbox }
  let(:facebook_inbox2) { facebook_channel2.inbox }

  let(:event_json) do
    {
      sender: { id: 'sender_1' },
      recipient: { id: 'shared_page_id' },
      timestamp: '1700000000000',
      postback: { title: 'Option A', payload: 'btn_1', mid: 'mid.original_send' }
    }.to_json
  end

  it 'processes the postback for every matching page/inbox' do
    described_class.perform_now(event_json)

    expect(facebook_inbox1.conversations.count).to eq 1
    expect(facebook_inbox2.conversations.count).to eq 1
  end

  it 'still dedupes a genuine duplicate delivery to the same inbox' do
    described_class.perform_now(event_json)
    described_class.perform_now(event_json)

    expect(facebook_inbox1.messages.incoming.count).to eq 1
    expect(facebook_inbox2.messages.incoming.count).to eq 1
  end
end
