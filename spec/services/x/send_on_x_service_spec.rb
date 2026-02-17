require 'rails_helper'

RSpec.describe X::SendOnXService do
  let(:x_client) { instance_double(X::Client) }
  let(:token_service) { instance_double(X::TokenService) }
  let(:status_update_service) { instance_double(Messages::StatusUpdateService, perform: true) }

  let(:channel) { create(:channel_x, profile_id: '12345') }
  let(:inbox) { channel.inbox }
  let(:contact) { create(:contact, account: inbox.account) }
  let(:contact_inbox) { create(:contact_inbox, inbox: inbox, contact: contact, source_id: '67890') }
  let(:conversation) do
    create(
      :conversation,
      inbox: inbox,
      contact: contact,
      contact_inbox: contact_inbox,
      additional_attributes: { x_user_id: '67890' }
    )
  end

  before do
    allow(channel).to receive(:client).and_return(x_client)
    allow(X::TokenService).to receive(:new).and_return(token_service)
    allow(token_service).to receive(:access_token).and_return('valid-token')
    allow(Messages::StatusUpdateService).to receive(:new).and_return(status_update_service)
  end

  describe '#perform' do
    context 'with direct messages' do
      it 'sends outgoing DM and updates source_id' do
        allow(x_client).to receive(:send_direct_message).and_return({ 'id' => 'dm-123' })

        message = create(:message, message_type: :outgoing, inbox: inbox, conversation: conversation, account: inbox.account, content: 'Hello')
        message.update!(source_id: nil)

        described_class.new(message: message).perform

        expect(x_client).to have_received(:send_direct_message).with(
          participant_id: '67890',
          text: 'Hello',
          attachments: nil
        )
        expect(message.reload.source_id).to eq('dm-123')
        expect(Messages::StatusUpdateService).to have_received(:new).with(message, 'delivered')
      end

      it 'sends DM with attachments' do
        allow(x_client).to receive(:upload_media).and_return({ 'media_id_string' => 'media-123' })
        allow(x_client).to receive(:send_direct_message).and_return({ 'id' => 'dm-124' })
        allow(Down).to receive(:download).and_return(double(read: 'file-data'))

        message = build(:message, message_type: :outgoing, inbox: inbox, conversation: conversation, account: inbox.account, content: 'Check this')
        attachment = message.attachments.new(account_id: message.account_id, file_type: :image)
        attachment.file.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png', content_type: 'image/png')
        message.save!

        described_class.new(message: message).perform

        expect(x_client).to have_received(:upload_media)
        expect(x_client).to have_received(:send_direct_message).with(
          participant_id: '67890',
          text: 'Check this',
          attachments: [{ media_id: 'media-123' }]
        )
      end
    end

    context 'with tweet replies' do
      let(:tweet_conversation) do
        create(
          :conversation,
          inbox: inbox,
          contact: contact,
          contact_inbox: contact_inbox,
          additional_attributes: { 'type' => 'tweet', 'tweet_id' => 'tweet-123' }
        )
      end

      it 'sends tweet reply when in_reply_to_external_id is present' do
        allow(x_client).to receive(:create_tweet).and_return({ 'data' => { 'id' => 'tweet-456' } })
        allow(x_client).to receive(:send_direct_message)

        # Create the original tweet message that we're replying to
        create(
          :message,
          message_type: :incoming,
          inbox: inbox,
          conversation: tweet_conversation,
          account: inbox.account,
          content: 'Original tweet',
          source_id: 'tweet-123'
        )

        message = create(
          :message,
          message_type: :outgoing,
          inbox: inbox,
          conversation: tweet_conversation,
          account: inbox.account,
          content: 'Reply tweet',
          content_attributes: { 'in_reply_to_external_id' => 'tweet-123' }
        )

        described_class.new(message: message).perform

        expect(x_client).to have_received(:create_tweet).with(
          text: 'Reply tweet',
          reply_to_tweet_id: 'tweet-123',
          media_ids: nil
        )
        expect(x_client).not_to have_received(:send_direct_message)
        expect(message.reload.source_id).to eq('tweet-456')
      end
    end

    context 'error handling' do
      it 'marks message as failed on API error' do
        allow(x_client).to receive(:send_direct_message).and_raise(X::Errors::ApiError, 'API error')

        message = create(:message, message_type: :outgoing, inbox: inbox, conversation: conversation, account: inbox.account, content: 'Hello')

        described_class.new(message: message).perform

        expect(Messages::StatusUpdateService).to have_received(:new).with(message, 'failed', 'API error')
      end

      it 'handles authorization errors and triggers reauthorization' do
        allow(x_client).to receive(:send_direct_message).and_raise(X::Errors::UnauthorizedError, 'Token expired')
        allow(channel).to receive(:authorization_error!)

        message = create(:message, message_type: :outgoing, inbox: inbox, conversation: conversation, account: inbox.account, content: 'Hello')

        described_class.new(message: message).perform

        expect(channel).to have_received(:authorization_error!)
        expect(Messages::StatusUpdateService).to have_received(:new).with(message, 'failed', 'Authorization failed')
      end

      it 'handles rate limit errors' do
        allow(x_client).to receive(:send_direct_message).and_raise(X::Errors::RateLimitError, 'Rate limit')

        message = create(:message, message_type: :outgoing, inbox: inbox, conversation: conversation, account: inbox.account, content: 'Hello')

        described_class.new(message: message).perform

        expect(Messages::StatusUpdateService).to have_received(:new).with(message, 'failed', 'Rate limit exceeded')
      end
    end

    it 'ensures valid token before sending' do
      allow(x_client).to receive(:send_direct_message).and_return({ 'id' => 'dm-123' })

      message = create(:message, message_type: :outgoing, inbox: inbox, conversation: conversation, account: inbox.account, content: 'Hello')

      described_class.new(message: message).perform

      expect(token_service).to have_received(:access_token)
    end
  end
end
