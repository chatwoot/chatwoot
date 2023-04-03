require 'rails_helper'

RSpec.describe DataImportJob, type: :job do
  subject(:job) { described_class.perform_later(data_import) }

  let!(:data_import) { create(:data_import) }
  let!(:invalid_data_import) { create(:data_import, :invalid_data_import) }
  let!(:existing_data_import) { create(:data_import, :existing_data_import) }

  it 'queues the job' do
    expect { job }.to have_enqueued_job(described_class)
      .with(data_import)
      .on_queue('low')
  end

  it 'imports data into the account' do
    csv_length = CSV.parse(data_import.import_file.download, headers: true).length

    described_class.perform_now(data_import)
    expect(data_import.account.contacts.count).to eq(csv_length)
    expect(data_import.reload.total_records).to eq(csv_length)
    expect(data_import.reload.processed_records).to eq(csv_length)
    expect(Contact.find_by(phone_number: '+918080808080')).to be_truthy
  end

  it 'imports erroneous data into the account' do
    notification_instance = AdministratorNotifications::ChannelNotificationsMailer.new
    admin_mailer = double

    allow(notification_instance).to receive(:mail).and_return(admin_mailer)

    csv_length = CSV.parse(invalid_data_import.import_file.download, headers: true).length
    described_class.perform_now(invalid_data_import)
    expect(invalid_data_import.account.contacts.count).to eq(csv_length - 1)
    expect(invalid_data_import.reload.total_records).to eq(csv_length)
    expect(invalid_data_import.reload.processed_records).to eq(csv_length - 1)
  end

  it 'imports existing email records' do
    contact = Contact.create!(email: 'cuzzell0@mozilla.org', account_id: existing_data_import.account_id)
    expect(contact.reload.phone_number).to be_nil

    csv_length = CSV.parse(existing_data_import.import_file.download, headers: true).length

    described_class.perform_now(existing_data_import)
    expect(existing_data_import.account.contacts.count).to eq(csv_length)
    expect(Contact.find_by(email: 'cuzzell0@mozilla.org').phone_number).to eq('+918080808080')
    expect(Contact.where(email: 'cuzzell0@mozilla.org').count).to eq(1)
  end

  it 'imports existing phone_number records' do
    contact = Contact.create!(account_id: existing_data_import.account_id, phone_number: '+918080808081')
    expect(contact.reload.email).to be_nil
    csv_length = CSV.parse(existing_data_import.import_file.download, headers: true).length

    described_class.perform_now(existing_data_import)
    expect(existing_data_import.account.contacts.count).to eq(csv_length)
    expect(Contact.find_by(phone_number: '+918080808081').email).to eq('mcreegan1@cornell.edu')
    expect(Contact.where(phone_number: '+918080808081').count).to eq(1)
  end

  it 'imports existing email and phone_number records' do
    phone_contact = Contact.create!(account_id: existing_data_import.account_id, phone_number: '+918080808081')
    email_contact = Contact.create!(account_id: existing_data_import.account_id, email: 'mcreegan1@cornell.edu')

    described_class.perform_now(existing_data_import)
    expect(phone_contact.reload.email).to be_nil
    expect(email_contact.reload.phone_number).to be_nil
  end
end
