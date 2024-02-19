require 'rails_helper'

RSpec.describe Notification::DeleteNotificationJob do
  let(:user) { create(:user) }
  let(:conversation) { create(:conversation) }

  context 'when enqueuing the job' do
    it 'enqueues the job to delete all notifications' do
      expect do
        described_class.perform_later(user.id, type: :all)
      end.to have_enqueued_job(described_class).on_queue('low')
    end

    it 'enqueues the job to delete read notifications' do
      expect do
        described_class.perform_later(user.id, type: :read)
      end.to have_enqueued_job(described_class).on_queue('low')
    end
  end

  context 'when performing the job' do
    before do
      create(:notification, user: user, read_at: nil)
      create(:notification, user: user, read_at: Time.current)
    end

    it 'deletes all notifications' do
      described_class.perform_now(user, type: :all)
      expect(user.notifications.count).to eq(0)
    end

    it 'deletes only read notifications' do
      described_class.perform_now(user, type: :read)
      expect(user.notifications.count).to eq(1)
      expect(user.notifications.where(read_at: nil).count).to eq(1)
    end
  end
end
