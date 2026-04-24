require 'rails_helper'

describe Messages::Facebook::MessageBuilder do
  subject(:message_builder) { described_class.new(incoming_fb_text_message, facebook_channel.inbox).perform }

  before do
    allow(Resolv).to receive(:getaddresses).and_call_original
    allow(Resolv).to receive(:getaddresses).with('www.example.com').and_return(['93.184.216.34'])
    allow(Resolv).to receive(:getaddresses).with('chatwoot-assets.local').and_return(['93.184.216.35'])
    stub_request(:post, /graph.facebook.com/)
    stub_request(:get, 'https://www.example.com/test.jpeg')
      .to_return(status: 200, body: 'image-data', headers: { 'Content-Type' => 'image/jpeg' })
  end

  let!(:facebook_channel) { create(:channel_facebook_page) }
  let!(:message_object) { build(:incoming_fb_text_message).to_json }
  let!(:incoming_fb_text_message) { Integrations::Facebook::MessageParser.new(message_object) }
  let(:fb_object) { double }

  describe '#perform' do
    it 'creates contact and message for the facebook inbox' do
      allow(Koala::Facebook::API).to receive(:new).and_return(fb_object)
      allow(fb_object).to receive(:get_object).and_return(
        {
          first_name: 'Jane',
          last_name: 'Dae',
          account_id: facebook_channel.inbox.account_id,
          profile_pic: 'https://chatwoot-assets.local/sample.png'
        }.with_indifferent_access
      )
      message_builder

      contact = facebook_channel.inbox.contacts.first
      message = facebook_channel.inbox.messages.first

      expect(contact.name).to eq('Jane Dae')
      expect(message.content).to eq('facebook message')
    end

    it 'increments channel authorization_error_count when error is thrown' do
      allow(Koala::Facebook::API).to receive(:new).and_return(fb_object)
      allow(fb_object).to receive(:get_object).and_raise(Koala::Facebook::AuthenticationError.new(500, 'Error validating access token'))
      message_builder

      expect(facebook_channel.authorization_error_count).to eq(2)
    end

    it 'raises exception for non profile account' do
      allow(Koala::Facebook::API).to receive(:new).and_return(fb_object)
      allow(fb_object).to receive(:get_object).and_raise(Koala::Facebook::ClientError.new(400, '',
                                                                                          {
                                                                                            'type' => 'OAuthException',
                                                                                            'message' => '(#100) No profile available for this user.',
                                                                                            'error_subcode' => 2_018_218,
                                                                                            'code' => 100
                                                                                          }))
      message_builder

      contact = facebook_channel.inbox.contacts.first
      # Refer: https://github.com/chatwoot/chatwoot/pull/3016 for this check
      default_name = 'John Doe'

      expect(facebook_channel.inbox.reload.contacts.count).to eq(1)
      expect(contact.name).to eq(default_name)
    end

    it 'marks echo messages as external echo messages' do
      allow(Koala::Facebook::API).to receive(:new).and_return(fb_object)
      allow(fb_object).to receive(:get_object).and_return(
        {
          first_name: 'Jane',
          last_name: 'Dae',
          account_id: facebook_channel.inbox.account_id,
          profile_pic: 'https://chatwoot-assets.local/sample.png'
        }.with_indifferent_access
      )

      echo_message_object = {
        messaging: {
          sender: { id: facebook_channel.page_id },
          recipient: { id: '3383290475046708' },
          message: { mid: 'm_echo_1', text: 'Echo testing', is_echo: true, app_id: '263902037430900' }
        }
      }.to_json
      echo_message = Integrations::Facebook::MessageParser.new(echo_message_object)

      described_class.new(echo_message, facebook_channel.inbox, outgoing_echo: true).perform

      message = facebook_channel.inbox.messages.find_by(source_id: 'm_echo_1')
      expect(message).to be_present
      expect(message.message_type).to eq('outgoing')
      expect(message.sender).to be_nil
      expect(message.status).to eq('delivered')
      expect(message.content_attributes['external_echo']).to be true
    end

    context 'when message contains a reel attachment' do
      let(:reel_message_object) do
        {
          messaging: {
            sender: { id: '3383290475046708' },
            recipient: { id: facebook_channel.page_id },
            timestamp: 1_772_452_164_516,
            message: {
              mid: 'm_reel_test',
              attachments: [
                {
                  type: 'reel',
                  payload: {
                    url: 'https://www.facebook.com/reel/123456',
                    title: 'Test Reel Title',
                    reel_video_id: 123_456
                  }
                }
              ]
            }
          }
        }.to_json
      end
      let(:reel_message) { Integrations::Facebook::MessageParser.new(reel_message_object) }

      before do
        allow(Koala::Facebook::API).to receive(:new).and_return(fb_object)
        allow(fb_object).to receive(:get_object).and_return(
          { first_name: 'Jane', last_name: 'Dae', profile_pic: 'https://chatwoot-assets.local/sample.png' }.with_indifferent_access
        )
      end

      it 'creates an ig_reel attachment without downloading the file' do
        expect(Down).not_to receive(:download)
        described_class.new(reel_message, facebook_channel.inbox).perform

        message = facebook_channel.inbox.messages.find_by(source_id: 'm_reel_test')
        expect(message).to be_present
        expect(message.attachments.first.file_type).to eq('ig_reel')
        expect(message.attachments.first.external_url).to eq('https://www.facebook.com/reel/123456')
        expect(message.attachments.first.file.attached?).to be false
      end

      it 'sets the reel URL as message content' do
        described_class.new(reel_message, facebook_channel.inbox).perform

        message = facebook_channel.inbox.messages.find_by(source_id: 'm_reel_test')
        expect(message.content).to eq('https://www.facebook.com/reel/123456')
      end
    end

    context 'when message contains a downloadable attachment' do
      let(:attachment_message_object) do
        {
          messaging: {
            sender: { id: '3383290475046708' },
            recipient: { id: facebook_channel.page_id },
            timestamp: 1_772_452_164_516,
            message: {
              mid: 'm_attachment_test',
              attachments: [
                {
                  type: 'share',
                  payload: {
                    url: attachment_url
                  }
                }
              ]
            }
          }
        }.to_json
      end
      let(:attachment_message) { Integrations::Facebook::MessageParser.new(attachment_message_object) }
      let(:attachment_url) { 'https://www.example.com/test.jpeg' }

      before do
        allow(Koala::Facebook::API).to receive(:new).and_return(fb_object)
        allow(fb_object).to receive(:get_object).and_return(
          { first_name: 'Jane', last_name: 'Dae', profile_pic: 'https://chatwoot-assets.local/sample.png' }.with_indifferent_access
        )
      end

      it 'downloads and attaches files for safe public URLs' do
        described_class.new(attachment_message, facebook_channel.inbox).perform

        message = facebook_channel.inbox.messages.find_by(source_id: 'm_attachment_test')
        expect(message).to be_present
        expect(message.attachments.first.file_type).to eq('image')
        expect(message.attachments.first.external_url).to eq(attachment_url)
        expect(message.attachments.first.file).to be_attached
      end

      it 'skips blocked attachment URLs' do
        blocked_message = Integrations::Facebook::MessageParser.new(
          attachment_message_object.gsub(attachment_url, 'http://127.0.0.1/blocked.jpeg')
        )

        expect do
          described_class.new(blocked_message, facebook_channel.inbox).perform
        end.not_to raise_error

        message = facebook_channel.inbox.messages.find_by(source_id: 'm_attachment_test')
        expect(message).to be_present
        expect(message.attachments).to be_empty
      end
    end

    context 'when lock to single conversation' do
      subject(:mocked_message_builder) do
        described_class.new(mocked_incoming_fb_text_message, facebook_channel.inbox).perform
      end

      let!(:mocked_message_object) { build(:mocked_message_text, sender_id: contact_inbox.source_id).to_json }
      let!(:mocked_incoming_fb_text_message) { Integrations::Facebook::MessageParser.new(mocked_message_object) }
      let(:contact) { create(:contact, name: 'Jane Dae') }
      let(:contact_inbox) { create(:contact_inbox, contact_id: contact.id, inbox_id: facebook_channel.inbox.id) }

      context 'when lock to single conversation is disabled' do
        before do
          facebook_channel.inbox.update!(lock_to_single_conversation: false)
          stub_request(:get, /graph.facebook.com/)
        end

        it 'creates a new conversation if existing conversation is not present' do
          inital_count = Conversation.count

          mocked_message_builder

          facebook_channel.inbox.reload

          expect(facebook_channel.inbox.conversations.count).to eq(1)
          expect(Conversation.count).to eq(inital_count + 1)
        end

        it 'will not create a new conversation if last conversation is not resolved' do
          existing_conversation = create(:conversation, account_id: facebook_channel.inbox.account.id, inbox_id: facebook_channel.inbox.id,
                                                        contact_id: contact.id, contact_inbox_id: contact_inbox.id,
                                                        status: :open)

          mocked_message_builder

          facebook_channel.inbox.reload

          expect(facebook_channel.inbox.conversations.last.id).to eq(existing_conversation.id)
        end

        it 'creates a new conversation if last conversation is resolved' do
          existing_conversation = create(:conversation, account_id: facebook_channel.inbox.account.id, inbox_id: facebook_channel.inbox.id,
                                                        contact_id: contact.id, contact_inbox_id: contact_inbox.id, status: :resolved)

          inital_count = Conversation.count

          mocked_message_builder

          facebook_channel.inbox.reload

          expect(facebook_channel.inbox.conversations.last.id).not_to eq(existing_conversation.id)
          expect(Conversation.count).to eq(inital_count + 1)
        end
      end

      context 'when lock to single conversation is enabled' do
        before do
          facebook_channel.inbox.update!(lock_to_single_conversation: true)
          stub_request(:get, /graph.facebook.com/)
        end

        it 'creates a new conversation if existing conversation is not present' do
          inital_count = Conversation.count
          mocked_message_builder

          facebook_channel.inbox.reload

          expect(facebook_channel.inbox.conversations.count).to eq(1)
          expect(Conversation.count).to eq(inital_count + 1)
        end

        it 'reopens last conversation if last conversation exists' do
          existing_conversation = create(:conversation, account_id: facebook_channel.inbox.account.id, inbox_id: facebook_channel.inbox.id,
                                                        contact_id: contact.id, contact_inbox_id: contact_inbox.id)

          inital_count = Conversation.count

          mocked_message_builder

          facebook_channel.inbox.reload

          expect(facebook_channel.inbox.conversations.last.id).to eq(existing_conversation.id)
          expect(Conversation.count).to eq(inital_count)
        end
      end
    end
  end
end
