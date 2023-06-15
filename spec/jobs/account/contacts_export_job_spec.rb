require 'rails_helper'

RSpec.describe Account::ContactsExportJob do
  subject(:job) { described_class.perform_later }

  let!(:account) { create(:account) }

  it 'enqueues the job' do
    expect { job }.to have_enqueued_job(described_class)
      .on_queue('low')
  end

  context 'when export_contacts' do
    before do
      create(:contact, account: account, phone_number: '+910808080818', email: 'test1@text.example')
      8.times do
        create(:contact, account: account)
      end
      create(:contact, account: account, phone_number: '+910808080808', email: 'test2@text.example')
    end

    it 'generates CSV file and attach to account' do
      mailer = double
      allow(AdministratorNotifications::ChannelNotificationsMailer).to receive(:with).with(account: account).and_return(mailer)
      allow(mailer).to receive(:contact_export_complete)

      described_class.perform_now(account.id, [])

      file_url = Rails.application.routes.url_helpers.rails_blob_url(account.contacts_export)

      expect(account.contacts_export).to be_present
      expect(file_url).to be_present
      expect(mailer).to have_received(:contact_export_complete).with(file_url)
    end

    it 'generates valid data export file' do
      described_class.perform_now(account.id, [])

      csv_data = CSV.parse(account.contacts_export.download, headers: true)
      first_row = csv_data[0]
      last_row = csv_data[csv_data.length - 1]
      first_contact = account.contacts.first
      last_contact = account.contacts.last

      expect(csv_data.length).to eq(account.contacts.count)

      expect([first_row['email'], last_row['email']]).to contain_exactly(first_contact.email, last_contact.email)
      expect([first_row['phone_number'], last_row['phone_number']]).to contain_exactly(first_contact.phone_number, last_contact.phone_number)
    end
  end
end
