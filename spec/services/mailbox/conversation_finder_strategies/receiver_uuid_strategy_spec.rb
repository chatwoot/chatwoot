require 'rails_helper'

RSpec.describe Mailbox::ConversationFinderStrategies::ReceiverUuidStrategy do
  let(:account) { create(:account) }
  let(:email_channel) { create(:channel_email, email: 'test@example.com', account: account) }
  let(:conversation) { create(:conversation, inbox: email_channel.inbox, account: account) }
  let(:mail) { Mail.new }

  describe '#find' do
    context 'when mail has valid reply+uuid format' do
      before do
        conversation.update!(uuid: '12345678-1234-1234-1234-123456789012')
        mail.to = 'reply+12345678-1234-1234-1234-123456789012@example.com'
      end

      it 'returns the conversation' do
        strategy = described_class.new(mail)
        expect(strategy.find).to eq(conversation)
      end
    end

    context 'when mail has uppercase UUID' do
      before do
        conversation.update!(uuid: '12345678-1234-1234-1234-123456789012')
        mail.to = 'reply+12345678-1234-1234-1234-123456789012@EXAMPLE.COM'
      end

      it 'returns the conversation (case-insensitive matching)' do
        strategy = described_class.new(mail)
        expect(strategy.find).to eq(conversation)
      end
    end

    context 'when mail has multiple recipients with valid UUID' do
      before do
        conversation.update!(uuid: 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee')
        mail.to = ['other@example.com', 'reply+aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee@example.com']
      end

      it 'extracts UUID from any recipient' do
        strategy = described_class.new(mail)
        expect(strategy.find).to eq(conversation)
      end
    end

    context 'when UUID does not exist in database' do
      before do
        mail.to = 'reply+99999999-9999-9999-9999-999999999999@example.com'
      end

      it 'returns nil' do
        strategy = described_class.new(mail)
        expect(strategy.find).to be_nil
      end
    end

    context 'when mail has no recipients' do
      it 'returns nil' do
        strategy = described_class.new(mail)
        expect(strategy.find).to be_nil
      end
    end

    context 'when mail recipient has malformed UUID' do
      before do
        mail.to = 'reply+not-a-valid-uuid@example.com'
      end

      it 'returns nil' do
        strategy = described_class.new(mail)
        expect(strategy.find).to be_nil
      end
    end

    context 'when mail recipient has no reply+ prefix' do
      before do
        conversation.update!(uuid: '12345678-1234-1234-1234-123456789012')
        mail.to = 'test+12345678-1234-1234-1234-123456789012@example.com'
      end

      it 'returns nil' do
        strategy = described_class.new(mail)
        expect(strategy.find).to be_nil
      end
    end

    context 'when mail recipient has additional text after UUID' do
      before do
        conversation.update!(uuid: '12345678-1234-1234-1234-123456789012')
        mail.to = 'reply+12345678-1234-1234-1234-123456789012-extra@example.com'
      end

      it 'returns nil (UUID must be exact)' do
        strategy = described_class.new(mail)
        expect(strategy.find).to be_nil
      end
    end
  end
end
