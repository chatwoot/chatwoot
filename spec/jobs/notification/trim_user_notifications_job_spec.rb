require 'rails_helper'

RSpec.describe Notification::TrimUserNotificationsJob do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:conversation) { create(:conversation, account: account) }

  it 'enqueues the job on low queue' do
    expect { described_class.perform_later(user.id) }
      .to have_enqueued_job(described_class).with(user.id).on_queue('low')
  end

  it 'does not delete notifications when under limit' do
    create_list(:notification, 5, user: user, account: account, primary_actor: conversation)
    expect { described_class.perform_now(user.id) }.not_to(change(Notification, :count))
  end

  it 'trims to 300 notifications keeping the most recent' do
    old_notifications = create_list(:notification, 50, user: user, account: account, primary_actor: conversation, created_at: 2.days.ago)
    recent_notifications = create_list(:notification, 300, user: user, account: account, primary_actor: conversation, created_at: 1.hour.ago)

    described_class.perform_now(user.id)

    expect(Notification.where(user_id: user.id).count).to eq(300)
    expect(Notification.where(id: old_notifications.map(&:id))).to be_empty
    expect(Notification.where(id: recent_notifications.map(&:id)).count).to eq(300)
  end

  it 'only affects the specified user' do
    other_user = create(:user, account: account)
    create_list(:notification, 310, user: user, account: account, primary_actor: conversation)
    create_list(:notification, 5, user: other_user, account: account, primary_actor: conversation)

    described_class.perform_now(user.id)

    expect(Notification.where(user_id: user.id).count).to eq(300)
    expect(Notification.where(user_id: other_user.id).count).to eq(5)
  end
end
