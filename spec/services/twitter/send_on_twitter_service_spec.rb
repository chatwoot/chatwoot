require 'rails_helper'

describe Twitter::SendOnTwitterService do
  subject(:send_reply_service) { described_class.new(message: message) }

  let(:twitter_client) { instance_double(::Twitty::Facade) }
  let(:twitter_response) { instance_double(::Twitty::Response) }
  let(:account) { create(:account) }
  let(:widget_inbox) { create(:inbox, account: account) }
  let(:twitter_channel) { create(:channel_twitter_profile, account: account) }
  let(:twitter_inbox) { create(:inbox, channel: twitter_channel, account: account) }
  let(:contact) { create(:contact, account: account, additional_attributes: { screen_name: 'test_user' }) }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: twitter_inbox) }
  let(:dm_conversation) do
    create(
      :conversation,
      contact: contact,
      inbox: twitter_inbox,
      contact_inbox: contact_inbox,
      additional_attributes: { type: 'direct_message' }
    )
  end
  let(:tweet_conversation) do
    create(
      :conversation,
      contact: contact,
      inbox: twitter_inbox,
      contact_inbox: contact_inbox,
      additional_attributes: { type: 'tweet', tweet_id: '1234' }
    )
  end

  before do
    allow(::Twitty::Facade).to receive(:new).and_return(twitter_client)
    allow(twitter_client).to receive(:send_direct_message).and_return(true)
    allow(twitter_client).to receive(:send_tweet_reply).and_return(twitter_response)
    allow(twitter_response).to receive(:status).and_return('200')
    allow(twitter_response).to receive(:body).and_return(JSON.parse({ id_str: '12345' }.to_json))
  end

  describe '#perform' do
    context 'without reply' do
      it 'if inbox channel is not twitter profile' do
        message = create(:message, message_type: 'outgoing', inbox: widget_inbox, account: account)
        expect { ::Twitter::SendOnTwitterService.new(message: message).perform }.to raise_error 'Invalid channel service was called'
        expect(twitter_client).not_to have_received(:send_direct_message)
      end

      it 'if message is private' do
        message = create(:message, message_type: 'outgoing', private: true, inbox: twitter_inbox, account: account)
        ::Twitter::SendOnTwitterService.new(message: message).perform
        expect(twitter_client).not_to have_received(:send_direct_message)
      end

      it 'if message has source_id' do
        message = create(:message, message_type: 'outgoing', source_id: '123', inbox: twitter_inbox, account: account)
        ::Twitter::SendOnTwitterService.new(message: message).perform
        expect(twitter_client).not_to have_received(:send_direct_message)
      end

      it 'if message is not outgoing' do
        message = create(:message, message_type: 'incoming', inbox: twitter_inbox, account: account)
        ::Twitter::SendOnTwitterService.new(message: message).perform
        expect(twitter_client).not_to have_received(:send_direct_message)
      end
    end

    context 'with reply' do
      it 'if conversation is a direct message' do
        create(:message, message_type: :incoming, inbox: twitter_inbox, account: account, conversation: dm_conversation)
        message = create(:message, message_type: :outgoing, inbox: twitter_inbox, account: account, conversation: dm_conversation)
        ::Twitter::SendOnTwitterService.new(message: message).perform
        expect(twitter_client).to have_received(:send_direct_message)
      end

      context 'when conversation is a tweet' do
        it 'creates a response with correct reply if reply to message is incoming' do
          create(
            :message,
            message_type: :incoming,
            sender: contact,
            source_id: 'test-source-id-1',
            inbox: twitter_inbox,
            account: account,
            conversation: tweet_conversation
          )
          message = create(:message, message_type: :outgoing, inbox: twitter_inbox, account: account, conversation: tweet_conversation)
          ::Twitter::SendOnTwitterService.new(message: message).perform
          expect(twitter_client).to have_received(:send_tweet_reply).with(
            reply_to_tweet_id: 'test-source-id-1',
            tweet: "@test_user #{message.content}"
          )
          expect(message.reload.source_id).to eq '12345'
        end

        it 'creates a response with correct reply if reply to message is outgoing' do
          outgoing_message = create(
            :message,
            message_type: :outgoing,
            source_id: 'test-source-id-1',
            inbox: twitter_inbox,
            account: account,
            conversation: tweet_conversation
          )
          reply_message = create(
            :message,
            message_type: :outgoing,
            inbox: twitter_inbox,
            account: account,
            conversation: tweet_conversation,
            in_reply_to: outgoing_message.id
          )
          ::Twitter::SendOnTwitterService.new(message: reply_message).perform
          expect(twitter_client).to have_received(:send_tweet_reply).with(
            reply_to_tweet_id: 'test-source-id-1',
            tweet: "@#{twitter_inbox.name} #{reply_message.content}"
          )
          expect(reply_message.reload.source_id).to eq '12345'
        end
      end
    end
  end
end
