require 'rails_helper'

describe Messages::Instagram::MessageBuilder do
  subject(:instagram_direct_message_builder) { described_class }

  before do
    stub_request(:post, /graph\.instagram\.com/)
    stub_request(:get, 'https://www.example.com/test.jpeg')
      .to_return(status: 200, body: '', headers: {})
  end

  let!(:account) { create(:account) }
  let!(:instagram_channel) { create(:channel_instagram, account: account, instagram_id: 'chatwoot-app-user-id-1') }
  let!(:instagram_inbox) { create(:inbox, channel: instagram_channel, account: account, greeting_enabled: false) }
  let!(:dm_params) { build(:instagram_message_create_event).with_indifferent_access }
  let!(:story_mention_params) { build(:instagram_story_mention_event).with_indifferent_access }
  let!(:shared_reel_params) { build(:instagram_shared_reel_event).with_indifferent_access }
  let!(:instagram_story_reply_event) { build(:instagram_story_reply_event).with_indifferent_access }
  let!(:instagram_message_reply_event) { build(:instagram_message_reply_event).with_indifferent_access }
  let!(:contact) { create(:contact, id: 'Sender-id-1', name: 'Jane Dae') }
  let!(:contact_inbox) { create(:contact_inbox, contact_id: contact.id, inbox_id: instagram_inbox.id, source_id: 'Sender-id-1') }
  let(:conversation) do
    create(:conversation, account_id: account.id, inbox_id: instagram_inbox.id, contact_id: contact.id)
  end
  let(:message) do
    create(:message, account_id: account.id, inbox_id: instagram_inbox.id, conversation_id: conversation.id, message_type: 'outgoing',
                     source_id: 'message-id-1')
  end

  describe '#perform' do
    before do
      instagram_channel.update(access_token: 'valid_instagram_token')

      stub_request(:get, %r{https://graph\.instagram\.com/.*?/Sender-id-1\?.*})
        .to_return(
          status: 200,
          body: {
            name: 'Jane',
            username: 'some_user_name',
            profile_pic: 'https://chatwoot-assets.local/sample.png',
            id: 'Sender-id-1',
            follower_count: 100,
            is_user_follow_business: true,
            is_business_follow_user: true,
            is_verified_user: false
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'creates contact and message for the instagram direct inbox' do
      messaging = dm_params[:entry][0]['messaging'][0]
      contact_inbox
      described_class.new(messaging, instagram_inbox).perform

      instagram_inbox.reload

      expect(instagram_inbox.conversations.count).to be 1
      expect(instagram_inbox.messages.count).to be 1

      message = instagram_inbox.messages.first
      expect(message.content).to eq('This is the first message from the customer')
    end

    it 'discard echo message already sent by chatwoot' do
      conversation
      message

      expect(instagram_inbox.conversations.count).to be 1
      expect(instagram_inbox.messages.count).to be 1

      messaging = dm_params[:entry][0]['messaging'][0]
      messaging[:message][:mid] = 'message-id-1' # Set same source_id as the existing message
      described_class.new(messaging, instagram_inbox, outgoing_echo: true).perform

      instagram_inbox.reload

      expect(instagram_inbox.conversations.count).to be 1
      expect(instagram_inbox.messages.count).to be 1
    end

    it 'discards duplicate messages from webhook events with the same message_id' do
      messaging = dm_params[:entry][0]['messaging'][0]
      described_class.new(messaging, instagram_inbox).perform

      initial_message_count = instagram_inbox.messages.count
      expect(initial_message_count).to be 1

      described_class.new(messaging, instagram_inbox).perform

      expect(instagram_inbox.messages.count).to eq initial_message_count
    end

    it 'creates message for shared reel' do
      messaging = shared_reel_params[:entry][0]['messaging'][0]
      described_class.new(messaging, instagram_inbox).perform

      message = instagram_inbox.messages.first
      expect(message.attachments.first.file_type).to eq('ig_reel')
      expect(message.attachments.first.external_url).to eq(
        shared_reel_params[:entry][0]['messaging'][0]['message']['attachments'][0]['payload']['url']
      )
    end

    it 'creates message with story id' do
      story_source_id = instagram_story_reply_event[:entry][0]['messaging'][0]['message']['mid']

      stub_request(:get, %r{https://graph\.instagram\.com/.*?/#{story_source_id}\?.*})
        .to_return(
          status: 200,
          body: {
            story: {
              mention: {
                id: 'chatwoot-app-user-id-1'
              }
            },
            from: {
              username: instagram_inbox.channel.instagram_id
            }
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      messaging = instagram_story_reply_event[:entry][0]['messaging'][0]
      described_class.new(messaging, instagram_inbox).perform

      message = instagram_inbox.messages.first

      expect(message.content).to eq('This is the story reply')
      expect(message.content_attributes[:story_sender]).to eq(instagram_inbox.channel.instagram_id)
      expect(message.content_attributes[:story_id]).to eq('chatwoot-app-user-id-1')
    end

    it 'creates message with reply to mid' do
      # Create first message to ensure reply to is valid
      first_messaging = dm_params[:entry][0]['messaging'][0]
      described_class.new(first_messaging, instagram_inbox).perform

      # Create second message with reply to mid
      messaging = instagram_message_reply_event[:entry][0]['messaging'][0]
      described_class.new(messaging, instagram_inbox).perform

      first_message = instagram_inbox.messages.first
      reply_message = instagram_inbox.messages.last

      expect(reply_message.content).to eq('This is message with replyto mid')
      expect(reply_message.content_attributes[:in_reply_to_external_id]).to eq(first_message.source_id)
    end

    it 'handles deleted story' do
      story_source_id = story_mention_params[:entry][0][:messaging][0]['message']['mid']

      stub_request(:get, %r{https://graph\.instagram\.com/.*?/#{story_source_id}\?.*})
        .to_return(status: 404, body: { error: { message: 'Story not found', code: 1_609_005 } }.to_json)

      messaging = story_mention_params[:entry][0][:messaging][0]
      described_class.new(messaging, instagram_inbox).perform

      message = instagram_inbox.messages.first

      expect(message.content).to eq('This story is no longer available.')
      expect(message.attachments.count).to eq(0)
    end

    it 'does not create message for unsupported file type' do
      conversation

      # try to create a message with unsupported file type
      story_mention_params[:entry][0][:messaging][0]['message']['attachments'][0]['type'] = 'unsupported_type'
      messaging = story_mention_params[:entry][0][:messaging][0]

      described_class.new(messaging, instagram_inbox, outgoing_echo: false).perform

      # Conversation should exist but no new message should be created
      expect(instagram_inbox.conversations.count).to be 1
      expect(instagram_inbox.messages.count).to be 0
    end

    it 'does not create message if the message is already exists' do
      message

      expect(instagram_inbox.conversations.count).to be 1
      expect(instagram_inbox.messages.count).to be 1

      messaging = dm_params[:entry][0]['messaging'][0]
      messaging[:message][:mid] = 'message-id-1' # Set same source_id as the existing message
      described_class.new(messaging, instagram_inbox, outgoing_echo: false).perform

      expect(instagram_inbox.conversations.count).to be 1
      expect(instagram_inbox.messages.count).to be 1
    end

    it 'handles authorization errors' do
      instagram_channel.update(access_token: 'invalid_token')

      # Stub the request to return authorization error status
      stub_request(:get, %r{https://graph\.instagram\.com/.*?/Sender-id-1\?.*})
        .to_return(
          status: 401,
          body: { error: { message: 'unauthorized access token', code: 190 } }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      messaging = dm_params[:entry][0]['messaging'][0]

      # The method should complete without raising an error
      expect do
        described_class.new(messaging, instagram_inbox).perform
      end.not_to raise_error
    end
  end

  context 'when lock to single conversation is disabled' do
    before do
      instagram_inbox.update!(lock_to_single_conversation: false)
    end

    it 'creates a new conversation if existing conversation is not present' do
      initial_count = Conversation.count
      messaging = dm_params[:entry][0]['messaging'][0]

      described_class.new(messaging, instagram_inbox).perform

      expect(instagram_inbox.conversations.count).to eq(1)
      expect(Conversation.count).to eq(initial_count + 1)
    end

    it 'will not create a new conversation if last conversation is not resolved' do
      existing_conversation = create(:conversation, account_id: account.id, inbox_id: instagram_inbox.id,
                                                    contact_id: contact.id, status: :open)

      messaging = dm_params[:entry][0]['messaging'][0]
      described_class.new(messaging, instagram_inbox).perform

      expect(instagram_inbox.conversations.last.id).to eq(existing_conversation.id)
    end

    it 'creates a new conversation if last conversation is resolved' do
      existing_conversation = create(:conversation, account_id: account.id, inbox_id: instagram_inbox.id,
                                                    contact_id: contact.id, status: :resolved)

      initial_count = Conversation.count
      messaging = dm_params[:entry][0]['messaging'][0]

      described_class.new(messaging, instagram_inbox).perform

      expect(instagram_inbox.conversations.last.id).not_to eq(existing_conversation.id)
      expect(Conversation.count).to eq(initial_count + 1)
    end
  end

  context 'when lock to single conversation is enabled' do
    before do
      instagram_inbox.update!(lock_to_single_conversation: true)
    end

    it 'creates a new conversation if existing conversation is not present' do
      initial_count = Conversation.count
      messaging = dm_params[:entry][0]['messaging'][0]

      described_class.new(messaging, instagram_inbox).perform

      expect(instagram_inbox.conversations.count).to eq(1)
      expect(Conversation.count).to eq(initial_count + 1)
    end

    it 'reopens last conversation if last conversation is resolved' do
      existing_conversation = create(:conversation, account_id: account.id, inbox_id: instagram_inbox.id,
                                                    contact_id: contact.id, status: :resolved)

      initial_count = Conversation.count
      messaging = dm_params[:entry][0]['messaging'][0]

      described_class.new(messaging, instagram_inbox).perform

      expect(instagram_inbox.conversations.last.id).to eq(existing_conversation.id)
      expect(Conversation.count).to eq(initial_count)
    end
  end

  describe '#fetch_story_link' do
    let(:story_data) do
      {
        'story' => {
          'mention' => {
            'link' => 'https://example.com/story-link',
            'id' => '18094414321535710'
          }
        },
        'from' => {
          'username' => 'instagram_user',
          'id' => '2450757355263608'
        },
        'id' => 'story-source-id-123'
      }.with_indifferent_access
    end

    before do
      # Stub the HTTP request to Instagram API
      stub_request(:get, %r{https://graph\.instagram\.com/.*?fields=story,from})
        .to_return(
          status: 200,
          body: story_data.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'saves story information when story mention is processed' do
      messaging = story_mention_params[:entry][0][:messaging][0]
      described_class.new(messaging, instagram_inbox).perform

      message = instagram_inbox.messages.first

      expect(message.content).to include('instagram_user')
      expect(message.attachments.count).to eq(1)
      expect(message.content_attributes[:story_sender]).to eq('instagram_user')
      expect(message.content_attributes[:story_id]).to eq('18094414321535710')
      expect(message.content_attributes[:image_type]).to eq('story_mention')
    end

    it 'handles deleted stories' do
      # Override the stub for this test to return a 404 error
      stub_request(:get, %r{https://graph\.instagram\.com/.*?fields=story,from})
        .to_return(
          status: 404,
          body: { error: { message: 'Story not found', code: 1_609_005 } }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      messaging = story_mention_params[:entry][0][:messaging][0]
      described_class.new(messaging, instagram_inbox).perform

      message = instagram_inbox.messages.first

      expect(message.content).to eq('This story is no longer available.')
      expect(message.attachments.count).to eq(0)
    end
  end
end
