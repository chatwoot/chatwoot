require 'rails_helper'

RSpec.describe Notification::RemoveDuplicateNotificationJob do
  let(:user) { create(:user) }
  let(:conversation) { create(:conversation) }

  it 'enqueues the job' do
    duplicate_notification = create(:notification, user: user, notification_type: 'conversation_creation', primary_actor: conversation)
    expect do
      described_class.perform_later(duplicate_notification)
    end.to have_enqueued_job(described_class)
      .on_queue('default')
  end

  it 'removes duplicate notifications' do
    create(:notification, user: user, notification_type: 'conversation_creation', primary_actor: conversation)
    duplicate_notification = create(:notification, user: user, notification_type: 'conversation_creation', primary_actor: conversation)

    described_class.perform_now(duplicate_notification)
    expect(Notification.count).to eq(1)
  end

  it 'does not remove notifications of a different primary_actor_type that share the same id' do
    conversation_notification = create(:notification, user: user, notification_type: 'conversation_creation', primary_actor: conversation)

    # Force a same-id collision across actor types (channel notification pointing at the conversation's id)
    channel_notification = build(:notification, user: user, account: conversation.account,
                                                notification_type: 'internal_chat_mention', primary_actor: conversation)
    channel_notification.assign_attributes(primary_actor_type: 'InternalChat::Channel', primary_actor_id: conversation.id)
    channel_notification.save!(validate: false)

    described_class.perform_now(channel_notification)

    expect(Notification.exists?(conversation_notification.id)).to be(true)
    expect(Notification.exists?(channel_notification.id)).to be(true)
  end
end
