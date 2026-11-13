require 'rails_helper'

RSpec.describe Instagram::UnifiedInboxBuilder do
  subject(:builder) do
    described_class.new(account: account, token_response: token_response,
                        instagram_account: { 'id' => 'ig1', 'username' => 'test_instagram' }, configuration_id: 'config1')
  end

  let(:account) { create(:account) }
  let(:token_response) { { 'access_token' => 'system_token' } }
  let(:subscription) do
    stub_request(:post, 'https://graph.facebook.com/v22.0/ig1/subscribed_apps')
      .with(headers: { 'Authorization' => 'Bearer system_token' }, query: { subscribed_fields: 'messages,message_reactions,messaging_seen' })
  end

  before { subscription.to_return(body: { success: true }.to_json) }

  it 'creates an Instagram inbox with a non-expiring system user token' do
    inbox, already_exists = builder.perform

    expect(already_exists).to be false
    expect(inbox.name).to eq('test_instagram')
    expect(inbox.channel).to have_attributes(auth_type: 'unified_login', instagram_id: 'ig1', provider_name: 'test_instagram',
                                             access_token: 'system_token', configuration_id: 'config1', expires_at: nil)
    expect(subscription).to have_been_requested.once
  end

  it 'reauthorizes an existing Instagram inbox without changing its identity or name' do
    channel = create(:channel_instagram, account: account, instagram_id: 'ig1')
    channel.inbox.update!(name: 'Support')
    conversation = create(:conversation, account: account, inbox: channel.inbox)
    message = create(:message, account: account, inbox: channel.inbox, conversation: conversation, content: 'Original message')
    channel.authorization_error!

    expect { builder.perform }.not_to change(Inbox, :count)

    expect(channel.reload.access_token).to eq('system_token')
    expect(channel).to be_unified_login
    expect(channel).not_to be_reauthorization_required
    expect(channel.inbox.name).to eq('Support')
    expect(channel.inbox.conversations.pluck(:id)).to eq([conversation.id])
    expect(channel.inbox.messages.pluck(:id, :content)).to eq([[message.id, 'Original message']])
  end

  it 'does not create an inbox or change credentials when subscription fails' do
    channel = create(:channel_instagram, account: account, instagram_id: 'ig1')
    old_token = channel[:access_token]
    stub_request(:post, 'https://graph.facebook.com/v22.0/ig1/subscribed_apps')
      .with(query: { subscribed_fields: 'messages,message_reactions,messaging_seen' })
      .to_return(status: 403, body: { error: { message: 'Permission denied' } }.to_json)

    expect { builder.perform }.to raise_error(Instagram::UnifiedLoginService::Error, 'Permission denied')
    expect(channel.reload[:access_token]).to eq(old_token)
    expect(channel).to be_instagram_login
  end

  it 'does not connect an Instagram account owned by another Chatwoot account' do
    create(:channel_instagram, instagram_id: 'ig1')

    expect { builder.perform }.to raise_error(ActiveRecord::RecordInvalid)
    expect(account.inboxes.count).to eq(0)
  end

  context 'when the token expires' do
    let(:token_response) { { 'access_token' => 'system_token', 'expires_in' => 3600 } }

    it 'records the expiration instead of applying the Instagram refresh protocol' do
      freeze_time do
        inbox, = builder.perform
        expect(inbox.channel.expires_at).to eq(1.hour.from_now)
        travel 2.hours
        expect(inbox.channel.access_token).to be_nil
      end
    end
  end

  context 'with a long system user token' do
    let(:token_response) { { 'access_token' => 'a' * 1500 } }

    before do
      stub_request(:post, 'https://graph.facebook.com/v22.0/ig1/subscribed_apps')
        .with(headers: { 'Authorization' => "Bearer #{token_response.fetch('access_token')}" },
              query: { subscribed_fields: 'messages,message_reactions,messaging_seen' })
        .to_return(body: { success: true }.to_json)
    end

    it 'preserves the complete token when persisted' do
      inbox, = builder.perform
      expect(inbox.channel.reload.access_token).to eq(token_response.fetch('access_token'))
    end
  end
end
