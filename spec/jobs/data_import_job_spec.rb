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
    csv_data = CSV.parse(invalid_data_import.import_file.download, headers: true)
    csv_length = csv_data.length

    expect(csv_data[0]['email']).to eq(csv_data[2]['email'])

    described_class.perform_now(invalid_data_import)
    expect(invalid_data_import.account.contacts.count).to eq(csv_length - 1)
    expect(invalid_data_import.reload.total_records).to eq(csv_length)
    expect(invalid_data_import.reload.processed_records).to eq(csv_length)
  end

  it 'imports existing email records' do
    csv_data = CSV.parse(existing_data_import.import_file.download, headers: true)

    contact = Contact.create!(email: csv_data[0]['email'], account_id: existing_data_import.account_id)
    expect(contact.reload.phone_number).to be_nil

    csv_length = csv_data.length

    described_class.perform_now(existing_data_import)
    expect(existing_data_import.account.contacts.count).to eq(csv_length)
    expect(Contact.find_by(email: csv_data[0]['email']).phone_number).to eq(csv_data[0]['phone_number'])
    expect(Contact.where(email: csv_data[0]['email']).count).to eq(1)
  end

  it 'imports existing phone_number records' do
    csv_data = CSV.parse(existing_data_import.import_file.download, headers: true)

    contact = Contact.create!(account_id: existing_data_import.account_id, phone_number: csv_data[1]['phone_number'])
    expect(contact.reload.email).to be_nil
    csv_length = csv_data.length

    described_class.perform_now(existing_data_import)
    expect(existing_data_import.account.contacts.count).to eq(csv_length)

    expect(Contact.find_by(phone_number: csv_data[1]['phone_number']).email).to eq(csv_data[1]['email'])
    expect(Contact.where(phone_number: csv_data[1]['phone_number']).count).to eq(1)
  end

  it 'imports existing email and phone_number records' do
    csv_data = CSV.parse(existing_data_import.import_file.download, headers: true)
    phone_contact = Contact.create!(account_id: existing_data_import.account_id, phone_number: csv_data[1]['phone_number'])
    email_contact = Contact.create!(account_id: existing_data_import.account_id, email: csv_data[1]['email'])

    csv_length = csv_data.length

    described_class.perform_now(existing_data_import)
    expect(phone_contact.reload.email).to be_nil
    expect(email_contact.reload.phone_number).to be_nil
    expect(existing_data_import.total_records).to eq(csv_length)
    expect(existing_data_import.processed_records).to eq(csv_length - 1)
  end
end
