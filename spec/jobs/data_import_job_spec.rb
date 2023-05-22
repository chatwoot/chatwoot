require 'rails_helper'

RSpec.describe DataImportJob do
  subject(:job) { described_class.perform_later(data_import) }

  let!(:data_import) { create(:data_import) }

  describe 'enqueueing the job' do
    it 'queues the job on the low priority queue' do
      expect { job }.to have_enqueued_job(described_class)
        .with(data_import)
        .on_queue('low')
    end
  end

  describe 'importing data' do
    context 'when the data is valid' do
      it 'imports data into the account' do
        csv_length = CSV.parse(data_import.import_file.download, headers: true).length

        described_class.perform_now(data_import)
        expect(data_import.account.contacts.count).to eq(csv_length)
        expect(data_import.reload.total_records).to eq(csv_length)
        expect(data_import.reload.processed_records).to eq(csv_length)
        contact = Contact.find_by(phone_number: '+918080808080')
        expect(contact).to be_truthy
        expect(contact['additional_attributes']['company']).to eq('My Company Name')
      end
    end

    context 'when the data contains errors' do
      it 'imports erroneous data into the account, skipping invalid records' do
        # Last record is invalid because of duplicate email
        invalid_data = [
          %w[id first_name last_name email phone_number],
          ['1', 'Clarice', 'Uzzell', 'cuzzell0@mozilla.org', '+918484848484'],
          ['2', 'Marieann', 'Creegan', 'mcreegan1@cornell.edu', '+918484848485'],
          ['3', 'Nancey', 'Windibank', 'cuzzell0@mozilla.org', '+91848484848']
        ]

        invalid_data_import = create(:data_import, import_file: generate_csv_file(invalid_data))
        csv_data = CSV.parse(invalid_data_import.import_file.download, headers: true)
        csv_length = csv_data.length

        described_class.perform_now(invalid_data_import)
        expect(invalid_data_import.account.contacts.count).to eq(csv_length - 1)
        expect(invalid_data_import.reload.total_records).to eq(csv_length)
        expect(invalid_data_import.reload.processed_records).to eq(csv_length)
      end
    end

    context 'when the data contains existing records' do
      let(:existing_data) do
        [
          %w[id first_name last_name email phone_number],
          ['1', 'Clarice', 'Uzzell', 'cuzzell0@mozilla.org', '+918080808080'],
          ['2', 'Marieann', 'Creegan', 'mcreegan1@cornell.edu', '+918080808081'],
          ['3', 'Nancey', 'Windibank', 'nwindibank2@bluehost.com', '+918080808082']
        ]
      end
      let(:existing_data_import) { create(:data_import, import_file: generate_csv_file(existing_data)) }
      let(:csv_data) { CSV.parse(existing_data_import.import_file.download, headers: true) }

      context 'when the existing record has an email in import data' do
        it 'updates the existing record with new data' do
          contact = Contact.create!(email: csv_data[0]['email'], account_id: existing_data_import.account_id)
          expect(contact.reload.phone_number).to be_nil

          csv_length = csv_data.length

          described_class.perform_now(existing_data_import)
          expect(existing_data_import.account.contacts.count).to eq(csv_length)
          expect(Contact.find_by(email: csv_data[0]['email']).phone_number).to eq(csv_data[0]['phone_number'])
          expect(Contact.where(email: csv_data[0]['email']).count).to eq(1)
        end
      end

      context 'when the existing record has a phone_number in import data' do
        it 'updates the existing record with new data' do
          contact = Contact.create!(account_id: existing_data_import.account_id, phone_number: csv_data[1]['phone_number'])
          expect(contact.reload.email).to be_nil
          csv_length = csv_data.length

          described_class.perform_now(existing_data_import)
          expect(existing_data_import.account.contacts.count).to eq(csv_length)

          expect(Contact.find_by(phone_number: csv_data[1]['phone_number']).email).to eq(csv_data[1]['email'])
          expect(Contact.where(phone_number: csv_data[1]['phone_number']).count).to eq(1)
        end
      end

      context 'when the existing record has both email and phone_number in import data' do
        it 'skips importing the records' do
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
    end
  end
end
