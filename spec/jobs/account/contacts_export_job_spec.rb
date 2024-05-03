require 'rails_helper'

RSpec.describe Account::ContactsExportJob do
  subject(:job) { described_class.perform_later }

  let(:account) { create(:account) }
  let(:user) { create(:user, account: account, email: 'account-user-test@test.com') }
  let(:email_filter) do
    {
      :attribute_key => 'email',
      :filter_operator => 'contains',
      :values => 'looped',
      :query_operator => 'and',
      :attribute_model => 'standard',
      :custom_attribute_type => ''
    }
  end

  let(:city_filter) do
    {
      :attribute_key => 'country_code',
      :filter_operator => 'equal_to',
      :values => 'IN',
      :query_operator => 'and',
      :attribute_model => 'standard',
      :custom_attribute_type => ''
    }
  end

  let(:single_filter) do
    {
      :payload => [email_filter]
    }
  end

  let(:multiple_filters) do
    {
      :payload => [city_filter, email_filter]
    }
  end

  it 'enqueues the job' do
    expect { job }.to have_enqueued_job(described_class)
      .on_queue('low')
  end

  context 'when export_contacts' do
    before do
      create(:contact, account: account, phone_number: '+910808080818', email: 'test1@text.example')
      4.times do |i|
        create(:contact, account: account, email: "looped-#{i + 3}@text.example.com")
      end
      4.times do |i|
        create(:contact, account: account, country_code: 'IN', email: "looped-#{i + 10}@text.example.com")
      end
      create(:contact, account: account, phone_number: '+910808080808', email: 'test2@text.example')
    end

    it 'generates CSV file and attach to account' do
      mailer = double
      allow(AdministratorNotifications::ChannelNotificationsMailer).to receive(:with).with(account: account).and_return(mailer)
      allow(mailer).to receive(:contact_export_complete)

      described_class.perform_now(account.id, [], [], user.id)

      file_url = Rails.application.routes.url_helpers.rails_blob_url(account.contacts_export)

      expect(account.contacts_export).to be_present
      expect(file_url).to be_present
      expect(mailer).to have_received(:contact_export_complete).with(file_url, user.email)
    end

    it 'generates valid data export file' do
      described_class.perform_now(account.id, %w[id name email phone_number column_not_present], [], user.id)

      csv_data = CSV.parse(account.contacts_export.download, headers: true)
      emails = csv_data.pluck('email')
      phone_numbers = csv_data.pluck('phone_number')

      expect(csv_data.length).to eq(account.contacts.count)

      expect(emails).to include('test1@text.example', 'test2@text.example')
      expect(phone_numbers).to include('+910808080818', '+910808080808')
    end

    it 'returns all results when filter is not prvoided' do
      described_class.perform_now(account.id, %w[id name email column_not_present], {}, user.id)
      csv_data = CSV.parse(account.contacts_export.download, headers: true)
      expect(csv_data.length).to eq(account.contacts.count)
    end

    it 'returns filtered data when multiple filters is provided' do
      described_class.perform_now(account.id, [], multiple_filters.with_indifferent_access, user.id)
      csv_data = CSV.parse(account.contacts_export.download, headers: true)
      # since there are only 8 contacts with 'looped' in email
      expect(csv_data.length).to eq(8)
    end

    it 'returns filtered data when a single filter is provided' do
      described_class.perform_now(account.id, [], single_filter.with_indifferent_access, user.id)
      csv_data = CSV.parse(account.contacts_export.download, headers: true)
      # since there are only 4 contacts with 'looped' in email and 'IN' as country_code
      expect(csv_data.length).to eq(4)
    end
  end
end
