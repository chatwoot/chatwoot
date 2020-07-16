# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ConversationReplyMailer, type: :mailer do
  describe 'reply' do
    let!(:account) { create(:account) }
    let!(:agent) { create(:user, email: 'agent1@example.com', account: account) }
    let(:class_instance) { described_class.new }

    before do
      allow(described_class).to receive(:new).and_return(class_instance)
      allow(class_instance).to receive(:smtp_config_set_or_development?).and_return(true)
    end

    context 'with summary' do
      let(:conversation) { create(:conversation, assignee: agent) }
      let(:message) { create(:message, conversation: conversation) }
      let(:private_message) { create(:message, content: 'This is a private message', conversation: conversation) }
      let(:mail) { described_class.reply_with_summary(message.conversation, Time.zone.now).deliver_now }

      it 'renders the subject' do
        expect(mail.subject).to eq("[##{message.conversation.display_id}] New messages on this conversation")
      end

      it 'not have private notes' do
        # make the message private
        private_message.private = true
        private_message.save

        expect(mail.body.decoded).not_to include(private_message.content)
        expect(mail.body.decoded).to include(message.content)
      end
    end

    context 'without summary' do
      let(:conversation) { create(:conversation, assignee: agent) }
      let(:message_1) { create(:message, conversation: conversation) }
      let(:message_2) { build(:message, conversation: conversation, message_type: 'outgoing', content: 'Outgoing Message') }
      let(:private_message) { create(:message, content: 'This is a private message', conversation: conversation) }
      let(:mail) { described_class.reply_without_summary(message_1.conversation, Time.zone.now - 1.minute).deliver_now }

      before do
        message_2.save
      end

      it 'renders the subject' do
        expect(mail.subject).to eq("[##{message_2.conversation.display_id}] New messages on this conversation")
      end

      it 'not have private notes' do
        # make the message private
        private_message.private = true
        private_message.save

        expect(mail.body.decoded).not_to include(private_message.content)
      end

      it 'onlies have the messages sent by the agent' do
        expect(mail.body.decoded).not_to include(message_1.content)
        expect(mail.body.decoded).to include(message_2.content)
      end
    end

    context 'when custom domain and email is not enabled' do
      let(:inbox) { create(:inbox, account: account) }
      let(:inbox_member) { create(:inbox_member, user: agent, inbox: inbox) }
      let(:conversation) { create(:conversation, assignee: agent, inbox: inbox_member.inbox, account: account) }
      let!(:message) { create(:message, conversation: conversation, account: account) }
      let(:mail) { described_class.reply_with_summary(message.conversation, Time.zone.now).deliver_now }

      it 'renders the receiver email' do
        expect(mail.to).to eq([message&.conversation&.contact&.email])
      end

      it 'renders the reply to email' do
        expect(mail.reply_to).to eq([message&.conversation&.assignee&.email])
      end

      it 'sets the correct custom message id' do
        expect(mail.message_id).to eq("<conversation/#{conversation.uuid}/messages/#{message.id}@>")
      end

      it 'sets the correct in reply to id' do
        expect(mail.in_reply_to).to eq("<account/#{conversation.account.id}/conversation/#{conversation.uuid}@>")
      end
    end

    context 'when the custom domain emails are enabled' do
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

      it 'sets the correct custom message id' do
        expect(mail.message_id).to eq("conversation/#{conversation.uuid}/messages/#{message.id}@#{conversation.account.domain}")
      end

      it 'sets the correct in reply to id' do
        expect(mail.in_reply_to).to eq("account/#{conversation.account.id}/conversation/#{conversation.uuid}@#{conversation.account.domain}")
      end
    end
  end
end
