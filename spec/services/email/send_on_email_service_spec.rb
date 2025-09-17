require 'rails_helper'

describe Email::SendOnEmailService do
  let(:account) { create(:account) }
  let(:email_channel) { create(:channel_email, account: account) }
  let(:inbox) { create(:inbox, account: account, channel: email_channel) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:message) { create(:message, conversation: conversation, message_type: 'outgoing') }
  let(:service) { described_class.new(message: message) }

  describe '#perform' do
    context 'when message is email notifiable' do
      before do
        allow(ConversationReplyMailer).to receive_message_chain(:with, :email_reply, :deliver_now)
      end

      it 'sends email via ConversationReplyMailer' do
        service.perform

        expect(ConversationReplyMailer).to have_received(:with).with(account: message.account)
      end
    end

    context 'when message is not email notifiable' do
      let(:message) { create(:message, conversation: conversation, message_type: 'incoming') }

      before do
        allow(ConversationReplyMailer).to receive_message_chain(:with, :email_reply, :deliver_now)
      end

      it 'does not send email' do
        service.perform

        expect(ConversationReplyMailer).not_to have_received(:with)
      end
    end

    context 'when an error occurs' do
      let(:error_message) { 'SMTP connection failed' }
      let(:error) { StandardError.new(error_message) }

      before do
        allow(ConversationReplyMailer).to receive_message_chain(:with, :email_reply, :deliver_now).and_raise(error)
        allow(ChatwootExceptionTracker).to receive(:new).and_return(double(capture_exception: true))
        allow(Messages::StatusUpdateService).to receive(:new).and_return(double(perform: true))
      end

      it 'captures the exception' do
        expect(ChatwootExceptionTracker).to receive(:new).with(error, account: message.account)

        service.perform
      end

      it 'updates message status to failed' do
        expect(Messages::StatusUpdateService).to receive(:new).with(message, 'failed', error_message)

        service.perform
      end
    end
  end

  describe '#channel_class' do
    it 'returns Channel::Email' do
      expect(service.send(:channel_class)).to eq(Channel::Email)
    end
  end

  describe 'inheritance' do
    it 'inherits from Base::SendOnChannelService' do
      expect(described_class.superclass).to eq(Base::SendOnChannelService)
    end
  end
end
