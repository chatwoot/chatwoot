require 'rails_helper'

RSpec.describe Instagram::UnifiedInboxBuilder do
  let(:account) { create(:account, limits: { inboxes: 1 }) }
  let(:builder) do
    described_class.new(account: account, token_response: { 'access_token' => 'system_token' },
                        instagram_account: { 'id' => 'ig1', 'username' => 'test' }, configuration_id: 'config1')
  end

  before do
    stub_request(:post, 'https://graph.facebook.com/v22.0/ig1/subscribed_apps')
      .with(query: { subscribed_fields: 'messages,message_reactions,messaging_seen' })
      .to_return(body: { success: true }.to_json)
  end

  it 'honors the inbox limit and rolls back the channel when creating an inbox' do
    create(:inbox, account: account)

    expect { builder.perform }.to raise_error(CustomExceptions::Inbox::LimitExceeded)
    expect(account.inboxes.count).to eq(1)
    expect(account.instagram_channels.count).to eq(0)
  end

  it 'allows reauthorization when the account is already at its inbox limit' do
    channel = create(:channel_instagram, account: account, instagram_id: 'ig1')

    inbox, already_exists = builder.perform

    expect(already_exists).to be true
    expect(inbox).to eq(channel.inbox)
    expect(channel.reload.access_token).to eq('system_token')
    expect(account.inboxes.count).to eq(1)
  end
end
