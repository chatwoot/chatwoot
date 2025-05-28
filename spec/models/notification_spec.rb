# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Notification do
  include ActiveJob::TestHelper

  context 'with associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:user) }
  end

  context 'with default order by' do
    it 'sort by primary id desc' do
      notification1 = create(:notification)
      create(:notification)
      notification3 = create(:notification)

      expect(described_class.all.first).to eq notification1
      expect(described_class.all.last).to eq notification3
    end
  end

  context 'when push_title is called' do
    it 'returns appropriate title suited for the notification type conversation_creation' do
      notification = create(:notification, notification_type: 'conversation_creation')
      expect(notification.push_message_title).to eq "A conversation (##{notification.primary_actor.display_id}) \
has been created in #{notification.primary_actor.inbox.name}"
    end

    it 'returns appropriate title suited for the notification type conversation_assignment' do
      notification = create(:notification, notification_type: 'conversation_assignment')
      expect(notification.push_message_title).to eq "A conversation (##{notification.primary_actor.display_id}) \
has been assigned to you"
    end

    it 'returns appropriate title suited for the notification type assigned_conversation_new_message' do
      message = create(:message, sender: create(:user), content: Faker::Lorem.paragraphs(number: 2))
      notification = create(:notification, notification_type: 'assigned_conversation_new_message', primary_actor: message.conversation,
                                           secondary_actor: message)

      expect(notification.push_message_title).to eq "A new message is created in conversation (##{notification.primary_actor.display_id})"
    end

    it 'returns appropriate title suited for the notification type assigned_conversation_new_message when attachment message' do
      # checking content nil should be suffice for attachments
      message = create(:message, sender: create(:user), content: nil)
      notification = create(:notification, notification_type: 'assigned_conversation_new_message', primary_actor: message.conversation,
                                           secondary_actor: message)

      expect(notification.push_message_title).to eq "A new message is created in conversation (##{notification.primary_actor.display_id})"
    end

    it 'returns appropriate title suited for the notification type participating_conversation_new_message' do
      message = create(:message, sender: create(:user), content: Faker::Lorem.paragraphs(number: 2))
      notification = create(:notification, notification_type: 'participating_conversation_new_message', primary_actor: message.conversation,
                                           secondary_actor: message)

      expect(notification.push_message_title).to eq "A new message is created in conversation (##{notification.primary_actor.display_id})"
    end

    it 'returns appropriate title suited for the notification type conversation_mention' do
      message = create(:message, sender: create(:user), content: 'Hey [@John](mention://user/1/john), can you check this ticket?')
      notification = create(:notification, notification_type: 'conversation_mention', primary_actor: message.conversation,
                                           secondary_actor: message)

      expect(notification.push_message_title).to eq "You have been mentioned in conversation (##{notification.primary_actor.display_id})"
    end
  end

  context 'when push_message_body is called' do
    it 'returns appropriate body suited for the notification type conversation_creation' do
      conversation = create(:conversation)
      message = create(:message, sender: create(:user), content: Faker::Lorem.paragraphs(number: 2), conversation: conversation)
      notification = create(:notification, notification_type: 'conversation_creation', primary_actor: conversation, secondary_actor: message)
      expect(notification.push_message_body).to eq "#{message.sender.name}: #{message.content.truncate_words(10)}"
    end

    it 'returns appropriate body suited for the notification type conversation_assignment' do
      conversation = create(:conversation)
      message = create(:message, sender: create(:user), content: Faker::Lorem.paragraphs(number: 2), conversation: conversation)
      notification = create(:notification, notification_type: 'conversation_assignment', primary_actor: conversation, secondary_actor: message)
      expect(notification.push_message_body).to eq "#{message.sender.name}: #{message.content.truncate_words(10)}"
    end

    it 'returns appropriate body suited for the notification type conversation_assignment with outgoing message only' do
      conversation = create(:conversation)
      message = create(:message, sender: create(:user), content: Faker::Lorem.paragraphs(number: 2), message_type: :outgoing,
                                 conversation: conversation)
      notification = create(:notification, notification_type: 'conversation_assignment', primary_actor: conversation, secondary_actor: message)
      expect(notification.push_message_body).to eq "#{message.sender.name}: #{message.content.truncate_words(10)}"
    end

    it 'returns appropriate body suited for the notification type assigned_conversation_new_message' do
      conversation = create(:conversation)
      message = create(:message, sender: create(:user), content: Faker::Lorem.paragraphs(number: 2), conversation: conversation)
      notification = create(:notification, notification_type: 'assigned_conversation_new_message', primary_actor: conversation,
                                           secondary_actor: message)
      expect(notification.push_message_body).to eq "#{message.sender.name}: #{message.content.truncate_words(10)}"
    end

    it 'returns appropriate body suited for the notification type assigned_conversation_new_message when attachment message' do
      conversation = create(:conversation)
      message = create(:message, sender: create(:user), content: nil, conversation: conversation)
      attachment = message.attachments.new(file_type: :image, account_id: message.account_id)
      attachment.file.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png', content_type: 'image/png')
      message.save!
      notification = create(:notification, notification_type: 'assigned_conversation_new_message', primary_actor: conversation,
                                           secondary_actor: message)
      expect(notification.push_message_body).to eq "#{message.sender.name}: Attachment"
    end

    it 'returns appropriate body suited for the notification type participating_conversation_new_message having multple mention' do
      conversation = create(:conversation)
      message = create(:message, sender: create(:user),
                                 content: 'Hey [@John](mention://user/1/john), [@Alisha Peter](mention://user/2/alisha) can you check this ticket?',
                                 conversation: conversation)
      notification = create(:notification, notification_type: 'participating_conversation_new_message', primary_actor: conversation,
                                           secondary_actor: message)
      expect(notification.push_message_body).to eq "#{message.sender.name}: Hey @John, @Alisha Peter can you check this ticket?"
    end

    it 'returns appropriate body suited for the notification type conversation_mention if username contains white space' do
      conversation = create(:conversation)
      message = create(:message, sender: create(:user), content: 'Hey [@John Peter](mention://user/1/john%20K) please check this?',
                                 conversation: conversation)
      notification = create(:notification, notification_type: 'conversation_mention', primary_actor: conversation, secondary_actor: message)
      expect(notification.push_message_body).to eq "#{message.sender.name}: Hey @John Peter please check this?"
    end

    it 'calls remove duplicate notification job' do
      allow(Notification::RemoveDuplicateNotificationJob).to receive(:perform_later)
      notification = create(:notification, notification_type: 'conversation_mention')
      expect(Notification::RemoveDuplicateNotificationJob).to have_received(:perform_later).with(notification)
    end
  end

  context 'when fcm push data' do
    it 'returns correct data for primary actor conversation' do
      notification = create(:notification, notification_type: 'conversation_creation')
      expect(notification.fcm_push_data[:primary_actor]).to eq({
                                                                 'id' => notification.primary_actor.display_id
                                                               })
    end

    it 'returns correct data for primary actor message' do
      message = create(:message, sender: create(:user), content: Faker::Lorem.paragraphs(number: 2))
      notification = create(:notification, notification_type: 'assigned_conversation_new_message', primary_actor: message.conversation,
                                           secondary_actor: message)
      expect(notification.fcm_push_data[:primary_actor]).to eq({
                                                                 'id' => notification.primary_actor.display_id
                                                               })
    end
  end

  context 'when primary actor is deleted' do
    let!(:conversation) { create(:conversation) }

    it 'clears notifications' do
      notification = create(:notification, notification_type: 'conversation_creation', primary_actor: conversation)
      perform_enqueued_jobs do
        conversation.inbox.destroy!
      end

      expect { notification.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
