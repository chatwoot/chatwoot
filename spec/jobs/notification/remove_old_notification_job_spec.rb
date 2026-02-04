require 'rails_helper'

RSpec.describe Notification::RemoveOldNotificationJob do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:conversation) { create(:conversation, account: account) }

  it 'enqueues the job' do
    expect do
      described_class.perform_later
    end.to have_enqueued_job(described_class)
      .on_queue('purgable')
  end

  describe 'removing old notifications' do
    it 'removes notifications older than 1 month' do
      create(:notification, user: user, notification_type: 'conversation_creation', primary_actor: conversation,
                            created_at: 2.months.ago)
      create(:notification, user: user, notification_type: 'conversation_creation', primary_actor: conversation,
                            created_at: 1.month.ago)
      create(:notification, user: user, notification_type: 'conversation_creation', primary_actor: conversation,
                            created_at: 1.day.ago)
      create(:notification, user: user, notification_type: 'conversation_creation', primary_actor: conversation,
                            created_at: 1.hour.ago)

      described_class.perform_now
      expect(Notification.count).to eq(2)
    end
  end

  describe 'trimming user notifications' do
    it 'does not delete notifications when user has fewer than 300' do
      create_list(:notification, 50, user: user, account: account, primary_actor: conversation)

      expect { described_class.perform_now }.not_to(change(Notification, :count))
    end

    it 'trims to 300 notifications per user keeping the most recent' do
      old_notifications = create_list(:notification, 50, user: user, account: account, primary_actor: conversation,
                                                         created_at: 2.days.ago)
      recent_notifications = create_list(:notification, 300, user: user, account: account, primary_actor: conversation,
                                                             created_at: 1.hour.ago)

      described_class.perform_now

      expect(Notification.where(user_id: user.id).count).to eq(300)
      expect(Notification.where(id: old_notifications.map(&:id))).to be_empty
      expect(Notification.where(id: recent_notifications.map(&:id)).count).to eq(300)
    end
  end

  describe 'combined functionality' do
    it 'removes old notifications and trims user notifications in one job' do
      # User with old and excess notifications
      create_list(:notification, 100, user: user, account: account, primary_actor: conversation, created_at: 2.months.ago)
      create_list(:notification, 250, user: user, account: account, primary_actor: conversation, created_at: 1.day.ago)

      described_class.perform_now

      # All old notifications removed, remaining trimmed to 300
      expect(Notification.where(user_id: user.id).count).to eq(250)
      expect(Notification.where('created_at < ?', 1.month.ago)).to be_empty
    end
  end
end
