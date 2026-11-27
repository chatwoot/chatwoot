require 'rails_helper'

RSpec.describe CaptainInbox do
  let(:account) { create(:account) }
  let!(:inbox) { create(:inbox, account: account) }
  let!(:assistant) { create(:captain_assistant, account: account) }

  it 'refreshes the cached inbox list when an assistant is connected' do
    expect(account).to receive(:update_cache_key).with('inbox')

    described_class.create!(inbox: inbox, captain_assistant: assistant)
  end

  it 'refreshes the cached inbox list when an assistant is disconnected' do
    captain_inbox = described_class.create!(inbox: inbox, captain_assistant: assistant)

    expect(account).to receive(:update_cache_key).with('inbox')

    captain_inbox.destroy!
  end
end
