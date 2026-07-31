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

  it 'preserves bot handoff event ids on the retained notification' do
    event_id = Time.zone.now.iso8601(6)
    create(
      :notification,
      user: user,
      notification_type: 'conversation_creation',
      primary_actor: conversation,
      created_at: 1.minute.ago,
      meta: { 'bot_handoff_event_ids' => [event_id] }
    )
    duplicate_notification = create(
      :notification,
      user: user,
      notification_type: 'conversation_assignment',
      primary_actor: conversation,
      created_at: Time.current
    )

    described_class.perform_now(duplicate_notification)

    expect(Notification.count).to eq(1)
    expect(duplicate_notification.reload.meta['bot_handoff_event_ids']).to contain_exactly(event_id)
  end
end
