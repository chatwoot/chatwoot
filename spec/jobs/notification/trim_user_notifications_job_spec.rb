require 'rails_helper'

RSpec.describe Notification::TrimUserNotificationsJob do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:conversation) { create(:conversation, account: account) }

  it 'enqueues the job' do
    expect { described_class.perform_later(user.id) }
      .to have_enqueued_job(described_class).with(user.id).on_queue('low')
  end

  context 'when user has fewer than 300 notifications' do
    before do
      create_list(:notification, 10, user: user, account: account, primary_actor: conversation)
    end

    it 'does not delete any notifications' do
      expect { described_class.perform_now(user.id) }.not_to change { Notification.count }
    end
  end

  context 'when user has exactly 300 notifications' do
    before do
      create_list(:notification, 300, user: user, account: account, primary_actor: conversation)
    end

    it 'does not delete any notifications' do
      expect { described_class.perform_now(user.id) }.not_to change { Notification.count }
    end
  end

  context 'when user has more than 300 notifications' do
    let!(:old_notifications) do
      create_list(:notification, 50, user: user, account: account, primary_actor: conversation, created_at: 2.days.ago)
    end
    let!(:recent_notifications) do
      create_list(:notification, 300, user: user, account: account, primary_actor: conversation, created_at: 1.hour.ago)
    end

    it 'keeps only the 300 most recent notifications' do
      described_class.perform_now(user.id)
      expect(Notification.where(user_id: user.id).count).to eq(300)
    end

    it 'deletes the oldest notifications' do
      described_class.perform_now(user.id)
      expect(Notification.where(id: old_notifications.map(&:id))).to be_empty
    end

    it 'keeps the recent notifications' do
      described_class.perform_now(user.id)
      expect(Notification.where(id: recent_notifications.map(&:id)).count).to eq(300)
    end
  end

  context 'with multiple users' do
    let(:user2) { create(:user, account: account) }

    before do
      create_list(:notification, 350, user: user, account: account, primary_actor: conversation)
      create_list(:notification, 100, user: user2, account: account, primary_actor: conversation)
    end

    it 'only affects the specified user notifications' do
      described_class.perform_now(user.id)
      expect(Notification.where(user_id: user.id).count).to eq(300)
      expect(Notification.where(user_id: user2.id).count).to eq(100)
    end
  end
end
