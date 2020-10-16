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
      let(:conversation) { create(:conversation, account: account, assignee: agent) }
      let(:message) { create(:message, account: account, conversation: conversation) }
      let(:private_message) { create(:message, account: account, content: 'This is a private message', conversation: conversation) }
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

      it 'will not send email if conversation is already viewed by contact' do
        create(:message, message_type: 'outgoing', account: account, conversation: conversation)
        conversation.update(contact_last_seen_at: Time.zone.now)
        expect(mail).to eq nil
      end
    end

    context 'without assignee' do
      let(:conversation) { create(:conversation, assignee: nil) }
      let(:message) { create(:message, conversation: conversation) }
      let(:mail) { described_class.reply_with_summary(message.conversation, Time.zone.now).deliver_now }

      it 'has correct name' do
        expect(mail[:from].display_names).to eq(['Notifications'])
      end
    end

    context 'without summary' do
      let(:conversation) { create(:conversation, assignee: agent, account: account).reload }
      let(:message_1) { create(:message, conversation: conversation, account: account, content: 'Outgoing Message 1').reload }
      let(:message_2) { build(:message, conversation: conversation, account: account, message_type: 'outgoing', content: 'Outgoing Message 2') }
      let(:private_message) do
        create(:message,
               content: 'This is a private message',
               conversation: conversation,
               account: account,
               message_type: 'outgoing').reload
      end
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

      it 'will not send email if conversation is already viewed by contact' do
        create(:message, message_type: 'outgoing', account: account, conversation: conversation)
        conversation.update(contact_last_seen_at: Time.zone.now)
        expect(mail).to eq nil
      end
    end

    context 'when custom domain and email is not enabled' do
      let(:inbox) { create(:inbox, account: account) }
      let(:inbox_member) { create(:inbox_member, user: agent, inbox: inbox) }
      let(:conversation) { create(:conversation, assignee: agent, inbox: inbox_member.inbox, account: account) }
      let!(:message) { create(:message, conversation: conversation, account: account) }
      let(:mail) { described_class.reply_with_summary(message.conversation, Time.zone.now).deliver_now }
      let(:domain) { account.domain || ENV.fetch('MAILER_INBOUND_EMAIL_DOMAIN', false) }

      it 'renders the receiver email' do
        expect(mail.to).to eq([message&.conversation&.contact&.email])
      end

      it 'renders the reply to email' do
        expect(mail.reply_to).to eq([message&.conversation&.assignee&.email])
      end

      it 'sets the correct custom message id' do
        expect(mail.message_id).to eq("conversation/#{conversation.uuid}/messages/#{message.id}@#{domain}")
      end

      it 'sets the correct in reply to id' do
        expect(mail.in_reply_to).to eq("account/#{conversation.account.id}/conversation/#{conversation.uuid}@#{domain}")
      end
    end

    context 'when inbox email address is available' do
      let(:inbox) { create(:inbox, account: account, email_address: 'noreply@chatwoot.com') }
      let(:conversation) { create(:conversation, assignee: agent, inbox: inbox, account: account) }
      let!(:message) { create(:message, conversation: conversation, account: account) }
      let(:mail) { described_class.reply_with_summary(message.conversation, Time.zone.now).deliver_now }

      it 'set reply to email address as inbox email address' do
        expect(mail.from).to eq([inbox.email_address])
        expect(mail.reply_to).to eq([inbox.email_address])
      end
    end

    context 'when the custom domain emails are enabled' do
      let(:account) { create(:account) }
      let(:conversation) { create(:conversation, assignee: agent, account: account).reload }
      let(:message) { create(:message, conversation: conversation, account: account, inbox: conversation.inbox) }
      let(:mail) { described_class.reply_with_summary(message.conversation, Time.zone.now).deliver_now }

      before do
        account = conversation.account
        account.domain = 'example.com'
        account.support_email = 'support@example.com'
        account.enable_features('inbound_emails')
        account.save!
      end

      it 'sets reply to email to be based on the domain' do
        reply_to_email = "reply+#{message.conversation.uuid}@#{conversation.account.domain}"
        reply_to = "#{agent.available_name} <#{reply_to_email}>"
        expect(mail['REPLY-TO'].value).to eq(reply_to)
        expect(mail.reply_to).to eq([reply_to_email])
      end

      it 'sets the from email to be the support email' do
        expect(mail['FROM'].value).to eq("#{agent.available_name} <#{conversation.account.support_email}>")
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
