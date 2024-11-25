require 'rails_helper'

RSpec.describe Notification::RemoveOldNotificationJob do
  let(:user) { create(:user) }
  let(:conversation) { create(:conversation) }

  it 'enqueues the job' do
    expect do
      described_class.perform_later
    end.to have_enqueued_job(described_class)
      .on_queue('low')
  end

  it 'removes old notifications which are older than 1 month' do
    create(:notification, user: user, notification_type: 'conversation_creation', primary_actor: conversation, created_at: 2.months.ago)
    create(:notification, user: user, notification_type: 'conversation_creation', primary_actor: conversation, created_at: 1.month.ago)
    create(:notification, user: user, notification_type: 'conversation_creation', primary_actor: conversation, created_at: 1.day.ago)
    create(:notification, user: user, notification_type: 'conversation_creation', primary_actor: conversation, created_at: 1.hour.ago)

    described_class.perform_now
    expect(Notification.count).to eq(2)
  end
end
