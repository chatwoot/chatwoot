require 'rails_helper'

describe Instagram::Direct::SendOnInstagramService do
  subject(:send_reply_service) { described_class.new(message: message) }

  before do
    stub_request(:post, /graph\.instagram\.com/)
    create(:message, message_type: :incoming, inbox: instagram_inbox, account: account, conversation: conversation)
  end

  let!(:account) { create(:account) }
  let!(:instagram_channel) { create(:channel_instagram, account: account, instagram_id: 'chatwoot-app-user-id-1') }
  let!(:instagram_inbox) { create(:inbox, channel: instagram_channel, account: account, greeting_enabled: false) }
  let!(:contact) { create(:contact, account: account) }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: instagram_inbox) }
  let(:conversation) { create(:conversation, contact: contact, inbox: instagram_inbox, contact_inbox: contact_inbox) }
  let(:mock_response) do
    instance_double(
      HTTParty::Response,
      success?: true,
      body: { message_id: 'anyrandommessageid1234567890' }.to_json,
      parsed_response: { 'message_id' => 'anyrandommessageid1234567890' }
    ).tap do |dbl|
      allow(dbl).to receive(:[]).and_return(nil)
      allow(dbl).to receive(:dig).and_return(nil)
    end
  end

  let(:error_body) do
    {
      'error' => {
        'message' => 'The Instagram account is restricted.',
        'type' => 'OAuthException',
        'code' => 400,
        'fbtrace_id' => 'anyrandomfbtraceid1234567890'
      }
    }
  end

  let(:error_response) do
    instance_double(
      HTTParty::Response,
      success?: false,
      body: error_body.to_json,
      parsed_response: error_body
    ).tap do |dbl|
      allow(dbl).to receive(:[]).with(:error).and_return(error_body['error'])
      allow(dbl).to receive(:[]).with('error').and_return(error_body['error'])
      allow(dbl).to receive(:dig).with('error', 'message').and_return(error_body['error']['message'])
      allow(dbl).to receive(:dig).with('error', 'code').and_return(error_body['error']['code'])
    end
  end

  let(:response_with_error) do
    instance_double(
      HTTParty::Response,
      success?: true,
      body: error_body.to_json,
      parsed_response: error_body
    ).tap do |dbl|
      allow(dbl).to receive(:[]).with(:error).and_return(error_body['error'])
      allow(dbl).to receive(:[]).with('error').and_return(error_body['error'])
      allow(dbl).to receive(:dig).with('error', 'message').and_return(error_body['error']['message'])
      allow(dbl).to receive(:dig).with('error', 'code').and_return(error_body['error']['code'])
    end
  end

  describe '#perform' do
    context 'with reply' do
      before do
        allow(HTTParty).to receive(:post).and_return(mock_response)
      end

      context 'without human_agent tag' do
        before do
          InstallationConfig.where(name: 'ENABLE_INSTAGRAM_CHANNEL_HUMAN_AGENT').first_or_create(value: false)
        end

        it 'sends message content only' do
          message = create(:message, message_type: 'outgoing', inbox: instagram_inbox, account: account, conversation: conversation)

          response = described_class.new(message: message).perform
          expect(response['message_id']).to eq('anyrandommessageid1234567890')
        end

        it 'sends message with multiple attachments' do
          message = build(:message, content: nil, message_type: 'outgoing', inbox: instagram_inbox, account: account, conversation: conversation)
          avatar = message.attachments.new(account_id: message.account_id, file_type: :image)
          avatar.file.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png', content_type: 'image/png')
          sample = message.attachments.new(account_id: message.account_id, file_type: :image)
          sample.file.attach(io: Rails.root.join('spec/assets/sample.png').open, filename: 'sample.png', content_type: 'image/png')
          message.save!

          service = described_class.new(message: message)

          # Stub the send_to_instagram method
          allow(service).to receive(:send_to_instagram)
          service.perform

          # Verify called twice for each attachment
          expect(service).to have_received(:send_to_instagram).exactly(:twice)
        end

        it 'sends message with attachment and content' do
          message = build(:message, content: 'Test content', message_type: 'outgoing', inbox: instagram_inbox, account: account,
                                    conversation: conversation)
          attachment = message.attachments.new(account_id: message.account_id, file_type: :image)
          attachment.file.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png', content_type: 'image/png')
          message.save!

          service = described_class.new(message: message)
          allow(service).to receive(:send_to_instagram).and_return(mock_response.parsed_response)

          service.perform

          # Verify called once for attachment and once for content
          expect(service).to have_received(:send_to_instagram).exactly(:twice)
        end

        it 'handles failed message delivery' do
          message = create(:message, message_type: 'outgoing', inbox: instagram_inbox, account: account, conversation: conversation)

          allow(HTTParty).to receive(:post).and_return(response_with_error)
          described_class.new(message: message).perform
          expect(HTTParty).to have_received(:post)
          expect(message.reload.status).to eq('failed')
          expect(message.reload.external_error).to eq('400 - The Instagram account is restricted.')
        end
      end

      context 'with human_agent tag' do
        before do
          InstallationConfig.where(name: 'ENABLE_INSTAGRAM_CHANNEL_HUMAN_AGENT').first_or_create(value: true)
        end

        it 'adds human_agent tag when within 7 day window' do
          # Create a recent incoming message to trigger the 7-day window condition
          create(:message,
                 message_type: 'incoming',
                 inbox: instagram_inbox,
                 account: account,
                 conversation: conversation,
                 created_at: 2.days.ago)

          message = create(:message, message_type: 'outgoing', inbox: instagram_inbox, account: account, conversation: conversation)

          expect_params = {
            recipient: { id: contact.get_source_id(instagram_inbox.id) },
            message: { text: message.content },
            messaging_type: 'MESSAGE_TAG',
            tag: 'human_agent'
          }

          allow(HTTParty).to receive(:post).with(
            'https://graph.instagram.com/v22.0/chatwoot-app-user-id-1/messages',
            hash_including(body: expect_params)
          ).and_return(mock_response)

          described_class.new(message: message).perform
          expect(HTTParty).to have_received(:post)
        end

        it 'does not add human_agent tag when outside 7 day window' do
          # Create an old incoming message outside the 7-day window
          create(:message,
                 message_type: 'incoming',
                 inbox: instagram_inbox,
                 account: account,
                 conversation: conversation,
                 created_at: 8.days.ago)

          message = create(:message, message_type: 'outgoing', inbox: instagram_inbox, account: account, conversation: conversation)

          expect_params = {
            recipient: { id: contact.get_source_id(instagram_inbox.id) },
            message: { text: message.content }
          }

          allow(HTTParty).to receive(:post).with(
            'https://graph.instagram.com/v22.0/chatwoot-app-user-id-1/messages',
            hash_including(body: expect_params)
          ).and_return(mock_response)

          described_class.new(message: message).perform
          expect(HTTParty).to have_received(:post)
        end
      end
    end

    context 'when handling errors' do
      it 'handles HTTP errors' do
        message = create(:message, message_type: 'outgoing', inbox: instagram_inbox, account: account, conversation: conversation)
        allow(HTTParty).to receive(:post).and_return(error_response)

        described_class.new(message: message).perform

        expect(message.reload.status).to eq('failed')
        expect(message.reload.external_error).to eq('400 - The Instagram account is restricted.')
      end

      it 'handles response errors' do
        message = create(:message, message_type: 'outgoing', inbox: instagram_inbox, account: account, conversation: conversation)

        error_data = { 'error' => { 'message' => 'Invalid message format', 'code' => 100 } }
        error_response = instance_double(
          HTTParty::Response,
          success?: true,
          body: error_data.to_json,
          parsed_response: error_data
        ).tap do |dbl|
          allow(dbl).to receive(:[]).with(:error).and_return(error_data['error'])
          allow(dbl).to receive(:[]).with('error').and_return(error_data['error'])
          allow(dbl).to receive(:dig).with('error', 'message').and_return(error_data['error']['message'])
          allow(dbl).to receive(:dig).with('error', 'code').and_return(error_data['error']['code'])
        end

        allow(HTTParty).to receive(:post).and_return(error_response)

        described_class.new(message: message).perform

        expect(message.reload.status).to eq('failed')
        expect(message.reload.external_error).to eq('100 - Invalid message format')
      end
    end
  end
end
