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

    before do
      create(:inbox_member, inbox: inbox, user: participating_agent_1)
      create(:inbox_member, inbox: inbox, user: participating_agent_2)
      create(:inbox_member, inbox: inbox, user: assignee)
      create(:conversation_participant, conversation: conversation, user: participating_agent_1)
      create(:conversation_participant, conversation: conversation, user: participating_agent_2)
      create(:conversation_participant, conversation: conversation, user: assignee)
    end

    context 'when message is created by a participant' do
      let(:message) { create(:message, conversation: conversation, account: account, sender: participating_agent_1) }

      before do
        described_class.new(message: message).perform
      end

      it 'creates notifications for other participating users' do
        expect(participating_agent_2.notifications.where(notification_type: 'participating_conversation_new_message', account: account,
                                                         primary_actor: message.conversation, secondary_actor: message)).to exist
      end

      it 'creates notifications for assignee' do
        expect(assignee.notifications.where(notification_type: 'assigned_conversation_new_message', account: account,
                                            primary_actor: message.conversation, secondary_actor: message)).to exist
      end

      it 'will not create notifications for the user who created the message' do
        expect(participating_agent_1.notifications.where(notification_type: 'participating_conversation_new_message',
                                                         account: account, primary_actor: message.conversation,
                                                         secondary_actor: message)).not_to exist
      end
    end

    context 'when message is created by a contact' do
      let(:message) { create(:message, conversation: conversation, account: account) }

      before do
        described_class.new(message: message).perform
      end

      it 'creates notifications for assignee' do
        expect(assignee.notifications.where(notification_type: 'assigned_conversation_new_message', account: account,
                                            primary_actor: message.conversation, secondary_actor: message)).to exist
      end

      it 'creates notifications for all participating users' do
        expect(participating_agent_1.notifications.where(notification_type: 'participating_conversation_new_message',
                                                         account: account, primary_actor: message.conversation,
                                                         secondary_actor: message)).to exist
        expect(participating_agent_2.notifications.where(notification_type: 'participating_conversation_new_message',
                                                         account: account, primary_actor: message.conversation,
                                                         secondary_actor: message)).to exist
      end
    end

    context 'when multiple notification conditions are met' do
      let(:message) { create(:message, conversation: conversation, account: account) }

      before do
        described_class.new(message: message).perform
      end

      it 'will not create participating notifications for the assignee if assignee notification was send' do
        expect(assignee.notifications.where(notification_type: 'assigned_conversation_new_message',
                                            account: account, primary_actor: message.conversation,
                                            secondary_actor: message)).to exist
        expect(assignee.notifications.where(notification_type: 'participating_conversation_new_message',
                                            account: account, primary_actor: message.conversation,
                                            secondary_actor: message)).not_to exist
      end
    end

    context 'when message is created by assignee' do
      let(:message) { create(:message, conversation: conversation, account: account, sender: assignee) }

      before do
        described_class.new(message: message).perform
      end

      it 'will not create notifications for the user who created the message' do
        expect(assignee.notifications.where(notification_type: 'participating_conversation_new_message',
                                            account: account, primary_actor: message.conversation,
                                            secondary_actor: message)).not_to exist
        expect(assignee.notifications.where(notification_type: 'assigned_conversation_new_message',
                                            account: account, primary_actor: message.conversation,
                                            secondary_actor: message)).not_to exist
      end
    end
  end
end
