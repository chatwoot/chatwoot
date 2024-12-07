require 'rails_helper'

RSpec.describe EmailReplyWorker, type: :worker do
  let(:account) { create(:account) }
  let(:channel) { create(:channel_email, account: account) }
  let(:message) { create(:message, message_type: :outgoing, inbox: channel.inbox, account: account) }
  let(:private_message) { create(:message, private: true, message_type: :outgoing, inbox: channel.inbox, account: account) }
  let(:incoming_message) { create(:message, message_type: :incoming, inbox: channel.inbox, account: account) }
  let(:template_message) { create(:message, message_type: :template, content_type: :input_csat, inbox: channel.inbox, account: account) }
  let(:mailer) { double }
  let(:mailer_action) { double }

  describe '#perform' do
    context 'when emails are successfully sent' do
      before do
        allow(ConversationReplyMailer).to receive(:with).and_return(mailer)
        allow(mailer).to receive(:email_reply).and_return(mailer_action)
        allow(mailer_action).to receive(:deliver_now).and_return(true)
      end

      it 'calls mailer action with message' do
        described_class.new.perform(message.id)
        expect(mailer).to have_received(:email_reply).with(message)
        expect(mailer_action).to have_received(:deliver_now)
      end

      it 'does not call mailer action with a private message' do
        described_class.new.perform(private_message.id)
        expect(mailer).not_to have_received(:email_reply)
        expect(mailer_action).not_to have_received(:deliver_now)
      end

      it 'calls mailer action with a CSAT message' do
        described_class.new.perform(template_message.id)
        expect(mailer).to have_received(:email_reply).with(template_message)
        expect(mailer_action).to have_received(:deliver_now)
      end

      it 'does not call mailer action with an incoming message' do
        described_class.new.perform(incoming_message.id)
        expect(mailer).not_to have_received(:email_reply)
        expect(mailer_action).not_to have_received(:deliver_now)
      end
    end

    context 'when emails are not sent' do
      before do
        allow(ConversationReplyMailer).to receive(:with).and_return(mailer)
        allow(mailer).to receive(:email_reply).and_return(mailer_action)
        allow(mailer_action).to receive(:deliver_now).and_raise(ArgumentError)
      end

      it 'mark message as failed' do
        expect { described_class.new.perform(message.id) }.to change { message.reload.status }.from('sent').to('failed')
      end
    end
  end
end
