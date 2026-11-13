require 'rails_helper'

RSpec.describe Instagram::MessageText do
  let(:channel) { create(:channel_instagram, auth_type: 'unified_login', expires_at: nil, instagram_id: 'unified-ig') }

  it 'fetches contact profiles using Facebook Graph with the Unified Login token' do
    request = stub_request(:get, 'https://graph.facebook.com/v22.0/contact-ig')
              .with(query: { fields: 'name,username,profile_pic,follower_count,is_user_follow_business,is_business_follow_user,is_verified_user',
                             access_token: channel.access_token })
              .to_return(body: { id: 'contact-ig', name: 'Instagram Contact', username: 'contact' }.to_json)
    messaging = {
      sender: { id: 'contact-ig' }, recipient: { id: channel.instagram_id },
      message: { mid: 'unified-message', text: 'Hello' }
    }.with_indifferent_access
    described_class.new(messaging, channel).perform

    expect(channel.inbox.messages.last.content).to eq('Hello')
    expect(channel.inbox.contacts.last.additional_attributes['social_instagram_user_name']).to eq('contact')
    expect(request).to have_been_requested.once
  end

  it 'fetches story replies using the inbox login type' do
    request = stub_request(:get, 'https://graph.facebook.com/v22.0/story-message')
              .with(query: { fields: 'story,from', access_token: channel.access_token })
              .to_return(body: { story: { id: 'story1' } }.to_json)
    builder = Messages::Instagram::MessageBuilder.new({}, channel.inbox)

    expect(builder.send(:get_story_object_from_source_id, 'story-message')).to include('story' => { 'id' => 'story1' })
    expect(request).to have_been_requested.once
  end

  it 'unsends the original outgoing message when Meta supplies its echo ID' do
    ids = JSON.parse(Rails.root.join('spec/fixtures/instagram/unified_login_message_ids.json').read)
    inbox = channel.inbox
    conversation = create(:conversation, account: inbox.account, inbox: inbox)
    message = create(:message, account: inbox.account, inbox: inbox, conversation: conversation,
                               message_type: :outgoing, source_id: ids.fetch('first_send'))
    messaging = {
      sender: { id: channel.instagram_id }, recipient: { id: 'contact-ig' },
      message: { mid: ids.fetch('first_echo'), is_echo: true, is_deleted: true }
    }.with_indifferent_access
    described_class.new(messaging, channel).perform

    expect(message.reload.deleted).to be(true)
    expect(message.content).to eq(I18n.t('conversations.messages.deleted'))
  end
end
