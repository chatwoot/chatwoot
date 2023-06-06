require 'rails_helper'

RSpec.describe Account::ContactsExportJob do
  subject(:job) { described_class.perform_later }

  let!(:account) { create(:account) }

  it 'enqueues the job' do
    expect { job }.to have_enqueued_job(described_class)
      .on_queue('low')
  end

  it 'send an email about export is completed' do
    expect(TeamNotifications::ContactNotificationMailer).to receive(:contact_export_notification).with(account)

    described_class.perform_now(account.id, [])

    path_to_file = "#{Rails.root}/public/contacts/#{account.id}/#{account.name}_#{account.id}_contacts.csv"

    expect(CSV.open(path_to_file, 'r')).to be_truthy
    File.delete(path_to_file)
  end
end
