require 'rails_helper'

RSpec.describe Mailbox::ConversationFinderStrategies::ReferencesStrategy do
  let(:account) { create(:account) }
  let(:email_channel) { create(:channel_email, email: 'test@example.com', account: account) }
  let(:conversation) { create(:conversation, inbox: email_channel.inbox, account: account) }
  let(:mail) { Mail.new }

  describe '#find' do
    context 'when references has message-specific pattern' do
      before do
        conversation.update!(uuid: '12345678-1234-1234-1234-123456789012')
        mail.to = 'test@example.com'
        mail.references = 'conversation/12345678-1234-1234-1234-123456789012/messages/123@example.com'
      end

      it 'extracts UUID and returns conversation' do
        strategy = described_class.new(mail)
        expect(strategy.find).to eq(conversation)
      end
    end

    context 'when references has conversation fallback pattern' do
      before do
        conversation.update!(uuid: 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee')
        mail.to = 'test@example.com'
        mail.references = "account/#{account.id}/conversation/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee@example.com"
      end

      it 'extracts UUID and returns conversation' do
        strategy = described_class.new(mail)
        expect(strategy.find).to eq(conversation)
      end
    end

    context 'when references matches message source_id' do
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
        mail.to = 'test@example.com'
        mail.references = 'original-message-id@example.com'
      end

      it 'finds conversation from message source_id' do
        strategy = described_class.new(mail)
        expect(strategy.find).to eq(conversation)
      end
    end

    context 'when references has multiple values' do
      before do
        conversation.update!(uuid: '12345678-1234-1234-1234-123456789012')
        mail.to = 'test@example.com'
        mail.references = [
          'some-random-message@gmail.com',
          'conversation/12345678-1234-1234-1234-123456789012/messages/123@example.com',
          'another-message@outlook.com'
        ]
      end

      it 'finds conversation from any reference' do
        strategy = described_class.new(mail)
        expect(strategy.find).to eq(conversation)
      end
    end

    context 'when references is blank' do
      it 'returns nil' do
        strategy = described_class.new(mail)
        expect(strategy.find).to be_nil
      end
    end

    context 'when references does not match any pattern or source_id' do
      before do
        mail.references = 'random-message-id@gmail.com'
      end

      it 'returns nil' do
        strategy = described_class.new(mail)
        expect(strategy.find).to be_nil
      end
    end

    context 'with channel validation' do
      context 'when conversation belongs to the correct channel' do
        before do
          conversation.update!(uuid: '12345678-1234-1234-1234-123456789012')
          mail.to = 'test@example.com'
          mail.references = 'conversation/12345678-1234-1234-1234-123456789012/messages/123@example.com'
        end

        it 'returns the conversation' do
          strategy = described_class.new(mail)
          expect(strategy.find).to eq(conversation)
        end
      end

      context 'when conversation belongs to a different channel' do
        let(:other_email_channel) { create(:channel_email, email: 'other@example.com', account: account) }
        let(:other_conversation) do
          create(
            :conversation,
            inbox: other_email_channel.inbox,
            account: account
          )
        end

        before do
          other_conversation.update!(uuid: 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee')
          # Mail is addressed to test@example.com but references conversation from other@example.com
          mail.to = 'test@example.com'
          mail.references = 'conversation/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee/messages/456@example.com'
        end

        it 'returns nil (prevents cross-channel hijacking)' do
          strategy = described_class.new(mail)
          expect(strategy.find).to be_nil
        end
      end

      context 'when channel cannot be determined from mail' do
        before do
          conversation.update!(uuid: '12345678-1234-1234-1234-123456789012')
          mail.to = 'unknown@example.com' # Email not associated with any channel
          mail.references = 'conversation/12345678-1234-1234-1234-123456789012/messages/123@example.com'
        end

        it 'returns nil' do
          strategy = described_class.new(mail)
          expect(strategy.find).to be_nil
        end
      end

      context 'when mail has multiple recipients including correct channel' do
        before do
          conversation.update!(uuid: '12345678-1234-1234-1234-123456789012')
          mail.to = ['other@example.com', 'test@example.com']
          mail.references = 'conversation/12345678-1234-1234-1234-123456789012/messages/123@example.com'
        end

        it 'finds the correct channel and returns conversation' do
          strategy = described_class.new(mail)
          expect(strategy.find).to eq(conversation)
        end
      end
    end

    context 'when UUID exists but conversation does not' do
      before do
        mail.to = 'test@example.com'
        mail.references = 'conversation/99999999-9999-9999-9999-999999999999/messages/123@example.com'
      end

      it 'returns nil' do
        strategy = described_class.new(mail)
        expect(strategy.find).to be_nil
      end
    end

    context 'with malformed references pattern' do
      before do
        mail.references = 'conversation/not-a-uuid/messages/123@example.com'
      end

      it 'returns nil' do
        strategy = described_class.new(mail)
        expect(strategy.find).to be_nil
      end
    end

    context 'when first reference fails channel validation but second succeeds' do
      let(:other_email_channel) { create(:channel_email, email: 'other@example.com', account: account) }
      let(:other_conversation) do
        create(
          :conversation,
          inbox: other_email_channel.inbox,
          account: account
        )
      end

      before do
        conversation.update!(uuid: '12345678-1234-1234-1234-123456789012')
        other_conversation.update!(uuid: 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee')

        mail.to = 'test@example.com'
        mail.references = [
          'conversation/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee/messages/456@example.com', # Wrong channel
          'conversation/12345678-1234-1234-1234-123456789012/messages/123@example.com'  # Correct channel
        ]
      end

      it 'skips invalid reference and returns conversation from valid reference' do
        strategy = described_class.new(mail)
        expect(strategy.find).to eq(conversation)
      end
    end
  end
end
