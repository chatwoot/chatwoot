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
        allow(Redis::Alfred).to receive(:set).and_return(true)
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

      it 'atomically sets redis key to prevent duplicate emails' do
        expected_key = format(Redis::Alfred::CONVERSATION_MAILER_KEY, conversation_id: conversation.id)

        service.perform

        expect(Redis::Alfred).to have_received(:set).with(expected_key, message.id, nx: true, ex: 1.hour.to_i)
      end

      context 'when redis key already exists' do
        before do
          allow(Redis::Alfred).to receive(:set).and_return(false)
        end

        it 'does not schedule worker' do
          service.perform

          expect(ConversationReplyEmailWorker).not_to have_received(:perform_in)
        end

        it 'attempts atomic set once' do
          service.perform

          expect(Redis::Alfred).to have_received(:set).once
        end
      end
    end

    context 'when handling concurrent requests' do
      let(:inbox) { create(:inbox, account: account, channel: create(:channel_widget, account: account, continuity_via_email: true)) }
      let(:conversation) { create(:conversation, account: account, inbox: inbox) }

      before do
        conversation.contact.update!(email: 'test@example.com')
      end

      it 'prevents duplicate workers under race conditions' do
        # Create 5 threads that simultaneously try to enqueue workers for the same conversation
        threads = Array.new(5) do
          Thread.new do
            msg = create(:message, conversation: conversation, message_type: 'outgoing')
            described_class.new(message: msg).perform
          end
        end

        threads.each(&:join)

        # Only ONE worker should be scheduled despite 5 concurrent attempts
        jobs_for_conversation = ConversationReplyEmailWorker.jobs.select { |job| job['args'].first == conversation.id }
        expect(jobs_for_conversation.size).to eq(1)
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
