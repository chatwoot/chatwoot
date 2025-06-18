require 'rails_helper'

describe MessageTemplates::Template::AutoResolve do
  let(:account) { create(:account, auto_resolve_message: 'Thanks for contacting us. This conversation has been resolved.') }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, inbox: inbox, account: account) }
  let(:service) { described_class.new(conversation: conversation) }

  describe '#perform' do
    context 'when auto resolve message is configured' do
      before do
        allow(Conversations::ActivityMessageJob).to receive(:perform_later)
      end

      context 'when within messaging window' do
        before do
          allow(conversation).to receive(:can_reply?).and_return(true)
        end

        it 'creates auto resolve template message' do
          expect { service.perform }.to change(conversation.messages, :count).by(1)

          message = conversation.messages.last
          expect(message.message_type).to eq('template')
          expect(message.content).to eq('Thanks for contacting us. This conversation has been resolved.')
        end
      end

      context 'when outside messaging window' do
        before do
          allow(conversation).to receive(:can_reply?).and_return(false)
        end

        it 'creates activity message instead of sending auto resolve message' do
          expect { service.perform }.not_to change(conversation.messages, :count)

          expect(Conversations::ActivityMessageJob).to have_received(:perform_later).with(
            conversation,
            hash_including(
              content: I18n.t('conversations.activity.auto_resolve.not_sent_due_to_messaging_window'),
              message_type: :activity
            )
          )
        end
      end
    end

    context 'when auto resolve message is not configured' do
      let(:account) { create(:account, auto_resolve_message: nil) }

      it 'does nothing when auto resolve message is blank' do
        expect { service.perform }.not_to change(conversation.messages, :count)
      end
    end

    context 'when auto resolve message is empty string' do
      let(:account) { create(:account, auto_resolve_message: '') }

      it 'does nothing when auto resolve message is empty' do
        expect { service.perform }.not_to change(conversation.messages, :count)
      end
    end
  end

  describe '#within_messaging_window?' do
    it 'delegates to conversation.can_reply?' do
      allow(conversation).to receive(:can_reply?).and_return(true)

      expect(service.send(:within_messaging_window?)).to be true
      expect(conversation).to have_received(:can_reply?)
    end
  end

  describe '#create_auto_resolve_not_sent_activity_message' do
    before do
      allow(Conversations::ActivityMessageJob).to receive(:perform_later)
    end

    it 'enqueues activity message job with correct parameters' do
      service.send(:create_auto_resolve_not_sent_activity_message)

      expect(Conversations::ActivityMessageJob).to have_received(:perform_later).with(
        conversation,
        {
          account_id: conversation.account_id,
          inbox_id: conversation.inbox_id,
          message_type: :activity,
          content: I18n.t('conversations.activity.auto_resolve.not_sent_due_to_messaging_window')
        }
      )
    end
  end
end