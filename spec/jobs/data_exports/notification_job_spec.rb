require 'rails_helper'

RSpec.describe DataExports::NotificationJob do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:record) { DataExports::CreationService.new(account: account, initiated_by: admin, options: {}).perform }

  it 'emails the operation page once after completion' do
    DataExports::ContactsJob.perform_now(record, record.active_run_id)
    expect do
      2.times { described_class.perform_now(record) }
    end.to change { ActionMailer::Base.deliveries.size }.by(1)
    expect(ActionMailer::Base.deliveries.last.body.encoded).to include("settings/data/exports/#{record.id}")
    expect(record.reload.notification_sent_at).to be_present
  end

  it 'does not send a completion email to a removed requester' do
    DataExports::ContactsJob.perform_now(record, record.active_run_id)
    account.account_users.find_by!(user: admin).destroy!
    expect { described_class.perform_now(record) }.not_to(change { ActionMailer::Base.deliveries.size })
  end
end
