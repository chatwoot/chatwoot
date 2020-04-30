# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ConversationReplyMailer, type: :mailer do
  describe 'reply_with_summary' do
    let(:agent) { create(:user, email: 'agent1@example.com') }
    let(:class_instance) { described_class.new }

    before do
      allow(described_class).to receive(:new).and_return(class_instance)
      allow(class_instance).to receive(:smtp_config_set_or_development?).and_return(true)
    end

    context 'when custom domain and email is not enabled' do
      let(:conversation) { create(:conversation, assignee: agent) }
      let(:message) { create(:message, conversation: conversation) }
      let(:mail) { described_class.reply_with_summary(message.conversation, Time.zone.now).deliver_now }

      it 'renders the subject' do
        expect(mail.subject).to eq("[##{message.conversation.display_id}] #{message.content.truncate(30)}")
      end

      it 'renders the receiver email' do
        expect(mail.to).to eq([message&.conversation&.contact&.email])
      end

      it 'renders the reply to email' do
        expect(mail.reply_to).to eq([message&.conversation&.assignee&.email])
      end
    end

    context 'when the cutsom domain emails are enabled' do
      let(:conversation) { create(:conversation, assignee: agent) }
      let(:message) { create(:message, conversation: conversation) }
      let(:mail) { described_class.reply_with_summary(message.conversation, Time.zone.now).deliver_now }

      before do
        account = conversation.account
        account.domain = 'example.com'
        account.support_email = 'support@example.com'
        account.domain_emails_enabled = true
        account.save
      end

      it 'sets reply to email to be based on the domain' do
        reply_to_email = "reply+to+#{message.conversation.uuid}@#{conversation.account.domain}"
        expect(mail.reply_to).to eq([reply_to_email])
      end

      it 'sets the from email to be the support email' do
        expect(mail.from).to eq([conversation.account.support_email])
      end
    end
  end
end
