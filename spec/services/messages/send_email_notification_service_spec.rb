require 'rails_helper'

describe Messages::SendEmailNotificationService do
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account) }
  let(:message) { create(:message, conversation: conversation, message_type: 'outgoing') }
  let(:service) { described_class.new(message: message) }

  describe '#perform' do
    context 'when email notification should be sent' do
      let(:inbox) { create(:inbox, account: account, channel: create(:channel_widget, account: account, continuity_via_email: true)) }
      let(:conversation) { create(:conversation, account: account, inbox: inbox) }

      before do
        conversation.contact.update!(email: 'test@example.com')
        allow(Redis::Alfred).to receive(:get).and_return(nil)
        allow(Redis::Alfred).to receive(:setex)
        allow(ConversationReplyEmailWorker).to receive(:perform_in)
      end

      it 'schedules ConversationReplyEmailWorker' do
        service.perform

        expect(ConversationReplyEmailWorker).to have_received(:perform_in).with(
          2.minutes,
          conversation.id,
          message.id
        )
      end

      it 'sets redis key to prevent duplicate emails' do
        expected_key = format(Redis::Alfred::CONVERSATION_MAILER_KEY, conversation_id: conversation.id)

        service.perform

        expect(Redis::Alfred).to have_received(:setex).with(expected_key, message.id)
      end

      context 'when redis key already exists' do
        before do
          allow(Redis::Alfred).to receive(:get).and_return('existing_key')
        end

        it 'does not schedule worker' do
          service.perform

          expect(ConversationReplyEmailWorker).not_to have_received(:perform_in)
        end

        it 'does not set redis key' do
          service.perform

          expect(Redis::Alfred).not_to have_received(:setex)
        end
      end
    end

    context 'when email notification should not be sent' do
      before do
        allow(ConversationReplyEmailWorker).to receive(:perform_in)
      end

      context 'when message is not email notifiable' do
        let(:message) { create(:message, conversation: conversation, message_type: 'incoming') }

        it 'does not schedule worker' do
          service.perform

          expect(ConversationReplyEmailWorker).not_to have_received(:perform_in)
        end
      end

      context 'when contact has no email' do
        let(:inbox) { create(:inbox, account: account, channel: create(:channel_widget, account: account, continuity_via_email: true)) }
        let(:conversation) { create(:conversation, account: account, inbox: inbox) }

        before do
          conversation.contact.update!(email: nil)
        end

        it 'does not schedule worker' do
          service.perform

          expect(ConversationReplyEmailWorker).not_to have_received(:perform_in)
        end
      end

      context 'when channel does not support email notifications' do
        let(:inbox) { create(:inbox, account: account, channel: create(:channel_sms, account: account)) }
        let(:conversation) { create(:conversation, account: account, inbox: inbox) }

        before do
          conversation.contact.update!(email: 'test@example.com')
        end

        it 'does not schedule worker' do
          service.perform

          expect(ConversationReplyEmailWorker).not_to have_received(:perform_in)
        end
      end
    end
  end

  describe '#should_send_email_notification?' do
    context 'with WebWidget channel' do
      let(:inbox) { create(:inbox, account: account, channel: create(:channel_widget, account: account, continuity_via_email: true)) }
      let(:conversation) { create(:conversation, account: account, inbox: inbox) }

      before do
        conversation.contact.update!(email: 'test@example.com')
      end

      it 'returns true when continuity_via_email is enabled' do
        expect(service.send(:should_send_email_notification?)).to be true
      end

      context 'when continuity_via_email is disabled' do
        let(:inbox) { create(:inbox, account: account, channel: create(:channel_widget, account: account, continuity_via_email: false)) }

        it 'returns false' do
          expect(service.send(:should_send_email_notification?)).to be false
        end
      end
    end

    context 'with API channel' do
      let(:inbox) { create(:inbox, account: account, channel: create(:channel_api, account: account)) }
      let(:conversation) { create(:conversation, account: account, inbox: inbox) }

      before do
        conversation.contact.update!(email: 'test@example.com')
        allow(account).to receive(:feature_enabled?).and_return(false)
        allow(account).to receive(:feature_enabled?).with('email_continuity_on_api_channel').and_return(true)
      end

      it 'returns true when email_continuity_on_api_channel feature is enabled' do
        expect(service.send(:should_send_email_notification?)).to be true
      end

      context 'when email_continuity_on_api_channel feature is disabled' do
        before do
          allow(account).to receive(:feature_enabled?).and_return(false)
          allow(account).to receive(:feature_enabled?).with('email_continuity_on_api_channel').and_return(false)
        end

        it 'returns false' do
          expect(service.send(:should_send_email_notification?)).to be false
        end
      end
    end

    context 'with other channels' do
      let(:inbox) { create(:inbox, account: account, channel: create(:channel_email, account: account)) }
      let(:conversation) { create(:conversation, account: account, inbox: inbox) }

      before do
        conversation.contact.update!(email: 'test@example.com')
      end

      it 'returns false' do
        expect(service.send(:should_send_email_notification?)).to be false
      end
    end
  end
end
