# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Notification do
  context 'with associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:user) }
  end

  context 'with default order by' do
    it 'sort by primary id desc' do
      notification1 = create(:notification)
      create(:notification)
      notification3 = create(:notification)

      expect(described_class.all.first).to eq notification3
      expect(described_class.all.last).to eq notification1
    end
  end

  context 'when push_title is called' do
    it 'returns appropriate title suited for the notification type conversation_creation' do
      notification = create(:notification, notification_type: 'conversation_creation')

      expect(notification.push_message_title).to eq "[New conversation] - ##{notification.primary_actor.display_id} has\
 been created in #{notification.primary_actor.inbox.name}"
    end

    it 'returns appropriate title suited for the notification type conversation_assignment' do
      notification = create(:notification, notification_type: 'conversation_assignment')

      expect(notification.push_message_title).to eq "[Assigned to you] - ##{notification.primary_actor.display_id} has been assigned to you"
    end

    it 'returns appropriate title suited for the notification type assigned_conversation_new_message' do
      notification = create(:notification, notification_type: 'assigned_conversation_new_message')

      expect(notification.push_message_title).to eq "[New message] - ##{notification.primary_actor.display_id} "
    end

    it 'returns appropriate title suited for the notification type conversation_mention' do
      message = create(:message, sender: create(:user))
      notification = create(:notification, notification_type: 'conversation_mention', primary_actor: message, secondary_actor: message.sender)

      expect(notification.push_message_title).to eq "You have been mentioned in conversation [ID - #{message.conversation.display_id}] \
by #{message.sender.name}"
    end
  end
end
