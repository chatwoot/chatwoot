require 'rails_helper'

describe Messages::NewMessageNotificationService do
  context 'when message is not notifiable' do
    it 'will not create any notifications' do
      message = build(:message, message_type: :activity)
      expect(NotificationBuilder).not_to receive(:new)
      described_class.new(message: message).perform
    end
  end

  context 'when message is notifiable' do
    let(:account) { create(:account) }
    let(:assignee) { create(:user, account: account) }
    let(:participating_agent_1) { create(:user, account: account) }
    let(:participating_agent_2) { create(:user, account: account) }
    let(:inbox) { create(:inbox, account: account) }
    let(:conversation) { create(:conversation, account: account, inbox: inbox, assignee: assignee) }
    let(:builder) { double }

    before do
      create(:inbox_member, inbox: inbox, user: participating_agent_1)
      create(:inbox_member, inbox: inbox, user: participating_agent_2)
      create(:inbox_member, inbox: inbox, user: assignee)
      create(:conversation_participant, conversation: conversation, user: participating_agent_1)
      create(:conversation_participant, conversation: conversation, user: participating_agent_2)
      create(:conversation_participant, conversation: conversation, user: assignee)
      allow(NotificationBuilder).to receive(:new).and_return(builder)
      allow(builder).to receive(:perform)
    end

    context 'when message is created by a participant' do
      let(:message) { create(:message, conversation: conversation, account: account, sender: participating_agent_1) }

      before do
        described_class.new(message: message).perform
      end

      it 'creates notifications for other participating users' do
        expect(NotificationBuilder).to have_received(:new).with(notification_type: 'participating_conversation_new_message',
                                                                user: participating_agent_2,
                                                                account: account,
                                                                primary_actor: message)
      end

      it 'creates notifications for assignee' do
        expect(NotificationBuilder).to have_received(:new).with(notification_type: 'assigned_conversation_new_message',
                                                                user: assignee,
                                                                account: account,
                                                                primary_actor: message)
      end

      it 'will not create notifications for the user who created the message' do
        expect(NotificationBuilder).not_to have_received(:new).with(notification_type: 'participating_conversation_new_message',
                                                                    user: participating_agent_1,
                                                                    account: account,
                                                                    primary_actor: message)
      end
    end

    context 'when message is created by a contact' do
      let(:message) { create(:message, conversation: conversation, account: account) }

      before do
        described_class.new(message: message).perform
      end

      it 'creates notifications for assignee' do
        expect(NotificationBuilder).to have_received(:new).with(notification_type: 'assigned_conversation_new_message',
                                                                user: assignee,
                                                                account: account,
                                                                primary_actor: message)
      end

      it 'creates notifications for all participating users' do
        expect(NotificationBuilder).to have_received(:new).with(notification_type: 'participating_conversation_new_message',
                                                                user: participating_agent_1,
                                                                account: account,
                                                                primary_actor: message)
        expect(NotificationBuilder).to have_received(:new).with(notification_type: 'participating_conversation_new_message',
                                                                user: participating_agent_2,
                                                                account: account,
                                                                primary_actor: message)
      end
    end

    context 'with multiple notifications are subscribed' do
      let(:message) { create(:message, conversation: conversation, account: account) }

      before do
        assignee.notification_settings.find_by(account_id: account.id).update(selected_email_flags: %w[email_assigned_conversation_new_message
                                                                                                       email_participating_conversation_new_message])
        described_class.new(message: message).perform
      end

      it 'will not create assignee notifications for the assignee if participating notification was send' do
        expect(NotificationBuilder).not_to have_received(:new).with(notification_type: 'assigned_conversation_new_message',
                                                                    user: assignee,
                                                                    account: account,
                                                                    primary_actor: message)
      end
    end

    context 'when message is created by assignee' do
      let(:message) { create(:message, conversation: conversation, account: account, sender: assignee) }

      before do
        described_class.new(message: message).perform
      end

      it 'will not create notifications for the user who created the message' do
        expect(NotificationBuilder).not_to have_received(:new).with(notification_type: 'participating_conversation_new_message',
                                                                    user: assignee,
                                                                    account: account,
                                                                    primary_actor: message)
        expect(NotificationBuilder).not_to have_received(:new).with(notification_type: 'assigned_conversation_new_message',
                                                                    user: assignee,
                                                                    account: account,
                                                                    primary_actor: message)
      end
    end
  end
end
