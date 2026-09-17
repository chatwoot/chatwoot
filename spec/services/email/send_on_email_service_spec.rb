require 'rails_helper'

describe Email::SendOnEmailService do
  let(:account) { create(:account) }
  let(:email_channel) { create(:channel_email, account: account) }
  let(:inbox) { create(:inbox, account: account, channel: email_channel) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:message) { create(:message, conversation: conversation, message_type: 'outgoing') }
  let(:service) { described_class.new(message: message) }

  describe '#perform with a forwarded email' do
    let(:agent) { create(:user, account: account) }
    let(:mailer) { ConversationReplyMailer.new }
    let(:conversation) do
      create(:conversation, account: account, inbox: inbox, additional_attributes: { 'mail_subject' => 'Order #42' })
    end
    let(:forwarded_message) { create(:message, conversation: conversation, message_type: 'incoming') }
    let(:forwarded_attachment) do
      attachment = forwarded_message.attachments.new(account_id: account.id, file_type: :image)
      attachment.file.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png', content_type: 'image/png')
      attachment.save!
      attachment
    end
    let(:params) do
      ActionController::Parameters.new(
        content: 'Please handle this',
        to_emails: 'vendor@example.com',
        email_html_content: '<p>Please handle this</p><p>Edited body</p>',
        content_attributes: { forwarded_message_id: forwarded_message.id }.to_json,
        forwarded_attachment_ids: [forwarded_attachment.id]
      )
    end
    let(:message) { Messages::MessageBuilder.new(agent, conversation, params).perform }

    before do
      allow(ConversationReplyMailer).to receive(:new).and_return(mailer)
      allow(mailer).to receive(:smtp_config_set_or_development?).and_return(true)
    end

    it 'delivers the forward to the new recipient as a fresh thread' do
      expect { service.perform }.to change { ActionMailer::Base.deliveries.count }.by(1)

      mail = ActionMailer::Base.deliveries.last
      expect(mail.to).to eq(['vendor@example.com'])
      expect(mail.subject).to eq('Fwd: Order #42')
      expect(mail.in_reply_to).to be_nil
      expect(mail.references).to be_nil
    end

    it 'sends the edited body with the original attachment and records the source id' do
      service.perform

      mail = ActionMailer::Base.deliveries.last
      expect(mail.html_part.decoded).to include('<p>Please handle this</p><p>Edited body</p>')
      expect(mail.attachments.map(&:filename)).to eq(['avatar.png'])
      expect(message.reload.source_id).to eq(mail.message_id)
    end
  end

  describe '#perform' do
    let(:mailer_context) { instance_double(ConversationReplyMailer) }
    let(:delivery) { instance_double(ActionMailer::MessageDelivery) }
    let(:email_message) { instance_double(Mail::Message) }

    before do
      allow(ConversationReplyMailer).to receive(:with).with(account: message.account).and_return(mailer_context)
    end

    context 'when message is email notifiable' do
      before do
        allow(mailer_context).to receive(:email_reply).with(message).and_return(delivery)
        allow(delivery).to receive(:deliver_now).and_return(email_message)
        allow(email_message).to receive(:message_id).and_return(
          "conversation/#{conversation.uuid}/messages/" \
          "#{message.id}@#{conversation.account.domain}"
        )
      end

      it 'sends email via ConversationReplyMailer' do
        service.perform

        expect(ConversationReplyMailer).to have_received(:with).with(account: message.account)
        expect(mailer_context).to have_received(:email_reply).with(message)
        expect(delivery).to have_received(:deliver_now)
      end

      it 'updates message source id on success' do
        service.perform

        expect(message.reload.source_id).to eq("conversation/#{conversation.uuid}/messages/#{message.id}@#{conversation.account.domain}")
      end
    end

    context 'when message is not email notifiable' do
      let(:message) { create(:message, conversation: conversation, message_type: 'incoming') }

      before do
        allow(mailer_context).to receive(:email_reply)
      end

      it 'does not send email' do
        service.perform

        expect(ConversationReplyMailer).not_to have_received(:with)
        expect(mailer_context).not_to have_received(:email_reply)
      end
    end

    context 'when an error occurs' do
      let(:error_message) { 'SMTP connection failed' }
      let(:error) { StandardError.new(error_message) }
      let(:exception_tracker) { instance_double(ChatwootExceptionTracker, capture_exception: true) }
      let(:status_service) { instance_double(Messages::StatusUpdateService, perform: true) }

      before do
        allow(mailer_context).to receive(:email_reply).with(message).and_return(delivery)
        allow(delivery).to receive(:deliver_now).and_raise(error)
        allow(ChatwootExceptionTracker).to receive(:new).and_return(exception_tracker)
      end

      it 'captures the exception' do
        expect(ChatwootExceptionTracker).to receive(:new).with(error, account: message.account)

        service.perform
      end

      it 'updates message status to failed' do
        service.perform

        expect(message.reload.status).to eq('failed')
        expect(message.reload.external_error).to eq(error_message)
      end
    end
  end
end
