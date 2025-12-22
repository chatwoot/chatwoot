require 'rails_helper'

RSpec.describe Mailbox::ConversationFinderStrategies::InReplyToStrategy do
  let(:account) { create(:account) }
  let(:email_channel) { create(:channel_email, email: 'test@example.com', account: account) }
  let(:conversation) { create(:conversation, inbox: email_channel.inbox, account: account) }
  let(:mail) { Mail.new }

  describe '#find' do
    context 'when in_reply_to has message-specific pattern' do
      before do
        conversation.update!(uuid: '12345678-1234-1234-1234-123456789012')
        mail.in_reply_to = 'conversation/12345678-1234-1234-1234-123456789012/messages/123@example.com'
      end

      it 'extracts UUID and returns conversation' do
        strategy = described_class.new(mail)
        expect(strategy.find).to eq(conversation)
      end
    end

    context 'when in_reply_to has conversation fallback pattern' do
      before do
        conversation.update!(uuid: 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee')
        mail.in_reply_to = "account/#{account.id}/conversation/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee@example.com"
      end

      it 'extracts UUID and returns conversation' do
        strategy = described_class.new(mail)
        expect(strategy.find).to eq(conversation)
      end
    end

    context 'when in_reply_to matches message source_id' do
      let(:message) do
        conversation.messages.create!(
          source_id: 'original-message-id@example.com',
          account_id: account.id,
          message_type: 'outgoing',
          inbox_id: email_channel.inbox.id,
          content: 'Original message'
        )
      end

      before do
        message # Create the message
        mail.in_reply_to = 'original-message-id@example.com'
      end

      it 'finds conversation from message source_id' do
        strategy = described_class.new(mail)
        expect(strategy.find).to eq(conversation)
      end
    end

    context 'when in_reply_to has multiple values' do
      let(:message) do
        conversation.messages.create!(
          source_id: 'message-123@example.com',
          account_id: account.id,
          message_type: 'outgoing',
          inbox_id: email_channel.inbox.id,
          content: 'Test message'
        )
      end

      before do
        message # Create the message
        mail.in_reply_to = ['some-other-id@example.com', 'message-123@example.com']
      end

      it 'finds conversation from any in_reply_to value' do
        strategy = described_class.new(mail)
        expect(strategy.find).to eq(conversation)
      end
    end

    context 'when in_reply_to is blank' do
      it 'returns nil' do
        strategy = described_class.new(mail)
        expect(strategy.find).to be_nil
      end
    end

    context 'when in_reply_to does not match any pattern or source_id' do
      before do
        mail.in_reply_to = 'random-message-id@gmail.com'
      end

      it 'returns nil' do
        strategy = described_class.new(mail)
        expect(strategy.find).to be_nil
      end
    end

    context 'when UUID exists but conversation does not' do
      before do
        mail.in_reply_to = 'conversation/99999999-9999-9999-9999-999999999999/messages/123@example.com'
      end

      it 'returns nil' do
        strategy = described_class.new(mail)
        expect(strategy.find).to be_nil
      end
    end

    context 'with malformed in_reply_to pattern' do
      before do
        mail.in_reply_to = 'conversation/not-a-uuid/messages/123@example.com'
      end

      it 'returns nil' do
        strategy = described_class.new(mail)
        expect(strategy.find).to be_nil
      end
    end
  end
end
