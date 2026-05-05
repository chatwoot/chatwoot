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

  describe 'retrying the job' do
    context 'when ActiveStorage::FileNotFoundError is raised' do
      let(:import_file_double) { instance_double(ActiveStorage::Blob) }

      before do
        allow(data_import).to receive(:import_file).and_return(import_file_double)
        allow(import_file_double).to receive(:open).and_raise(ActiveStorage::FileNotFoundError)
      end

      it 'retries the job' do
        expect do
          described_class.perform_now(data_import)
        end.to have_enqueued_job(described_class).at_least(1).times
      end
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
        expect(contact['additional_attributes']['company_name']).to eq('My Company Name')
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

      it 'will preserve emojis' do
        data_import = create(:data_import,
                             import_file: Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/data_import/with_emoji.csv'),
                                                                       'text/csv'))
        csv_data = CSV.parse(data_import.import_file.download, headers: true)
        csv_length = csv_data.length

        described_class.perform_now(data_import)
        expect(data_import.account.contacts.count).to eq(csv_length)

        expect(data_import.account.contacts.first.name).to eq('T 🏠 🔥 Test')
      end

      it 'will not throw error for non utf-8 characters' do
        invalid_data_import = create(:data_import,
                                     import_file: Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/data_import/invalid_bytes.csv'),
                                                                               'text/csv'))
        csv_data = CSV.parse(invalid_data_import.import_file.download, headers: true)
        csv_length = csv_data.length

        described_class.perform_now(invalid_data_import)
        expect(invalid_data_import.account.contacts.count).to eq(csv_length)

        expect(invalid_data_import.account.contacts.first.name).to eq(csv_data[0]['name'].encode('UTF-8', 'binary', invalid: :replace,
                                                                                                                    undef: :replace, replace: ''))
      end

      it 'will strip UTF-8 BOM and import contacts correctly' do
        bom_data_import = create(:data_import,
                                 import_file: Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/data_import/with_bom.csv'),
                                                                           'text/csv'))

        described_class.perform_now(bom_data_import)
        expect(bom_data_import.account.contacts.count).to eq(1)

        contact = bom_data_import.account.contacts.first
        expect(contact.name).to eq('Ahmed')
        expect(contact.email).to eq('ahmed@example.com')
        expect(contact.phone_number).to eq('+971501234567')
      end
    end

    context 'when the data contains existing records' do
      let(:existing_data) do
        [
          %w[id name email phone_number company_name],
          ['1', 'Clarice Uzzell', 'cuzzell0@mozilla.org', '918080808080', 'Acmecorp'],
          ['2', 'Marieann Creegan', 'mcreegan1@cornell.edu', '+918080808081', 'Acmecorp'],
          ['3', 'Nancey Windibank', 'nwindibank2@bluehost.com', '+918080808082', 'Acmecorp']
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
          contact = Contact.from_email(csv_data[0]['email'])
          expect(contact).to be_present
          expect(contact.phone_number).to eq("+#{csv_data[0]['phone_number']}")
          expect(contact.name).to eq((csv_data[0]['name']).to_s)
          expect(contact.additional_attributes['company_name']).to eq((csv_data[0]['company_name']).to_s)
        end
      end

      context 'when the existing record has a phone_number in import data' do
        it 'updates the existing record with new data' do
          contact = Contact.create!(account_id: existing_data_import.account_id, phone_number: csv_data[1]['phone_number'])
          expect(contact.reload.email).to be_nil
          csv_length = csv_data.length

          described_class.perform_now(existing_data_import)
          expect(existing_data_import.account.contacts.count).to eq(csv_length)

          contact = Contact.find_by(phone_number: "+#{csv_data[0]['phone_number']}")
          expect(contact).to be_present
          expect(contact.email).to eq(csv_data[0]['email'])
          expect(contact.name).to eq((csv_data[0]['name']).to_s)
          expect(contact.additional_attributes['company_name']).to eq((csv_data[0]['company_name']).to_s)
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

    context 'when the CSV file is invalid' do
      let(:invalid_csv_content) do
        "id,name,email,phone_number,company_name\n" \
          "1,\"Clarice Uzzell,\"missing_quote,918080808080,Acmecorp\n" \
          '2,Marieann Creegan,,+918080808081,Acmecorp'
      end

      before do
        import_file_double = instance_double(ActiveStorage::Blob)
        allow(data_import).to receive(:import_file).and_return(import_file_double)
        allow(import_file_double).to receive(:open).and_yield(StringIO.new(invalid_csv_content))
      end

      it 'does not import any data and handles the MalformedCSVError' do
        expect { described_class.perform_now(data_import) }
          .to change { data_import.reload.status }.from('pending').to('failed')
      end
    end

    context 'when the data contains labels column' do
      let(:data_with_labels) do
        [
          %w[id name email phone_number labels],
          ['1', 'John Doe', 'john@example.com', '+918080808080', 'customer,vip'],
          ['2', 'Jane Smith', 'jane@example.com', '+918080808081', 'lead'],
          ['3', 'Bob Wilson', 'bob@example.com', '+918080808082', '']
        ]
      end
      let(:labels_data_import) { create(:data_import, import_file: generate_csv_file(data_with_labels)) }

      before do
        %w[customer vip lead].each do |title|
          create(:label, account: labels_data_import.account, title: title)
        end
      end

      it 'imports contacts with labels from CSV' do
        described_class.perform_now(labels_data_import)

        john = Contact.from_email('john@example.com')
        expect(john).to be_present
        expect(john.label_list).to contain_exactly('customer', 'vip')

        jane = Contact.from_email('jane@example.com')
        expect(jane).to be_present
        expect(jane.label_list).to contain_exactly('lead')

        bob = Contact.from_email('bob@example.com')
        expect(bob).to be_present
        expect(bob.label_list).to be_empty
      end

      it 'handles labels with extra whitespace' do
        data_with_whitespace = [
          %w[id name email phone_number labels],
          ['1', 'Test User', 'test@example.com', '+918080808083', ' customer , vip , lead ']
        ]
        whitespace_import = create(:data_import, import_file: generate_csv_file(data_with_whitespace))
        %w[customer vip lead].each do |title|
          create(:label, account: whitespace_import.account, title: title)
        end

        described_class.perform_now(whitespace_import)

        contact = Contact.from_email('test@example.com')
        expect(contact.label_list).to contain_exactly('customer', 'vip', 'lead')
      end

      it 'adds imported labels to existing contact labels' do
        existing_contact = create(:contact, account: labels_data_import.account, email: 'labeled@example.com')
        existing_contact.add_labels(%w[customer vip])
        data_with_existing_contact = [
          %w[id name email phone_number labels],
          ['1', 'Labeled User', existing_contact.email, '+918080808086', 'lead']
        ]
        existing_contact_import = create(:data_import, account: labels_data_import.account,
                                                       import_file: generate_csv_file(data_with_existing_contact))

        described_class.perform_now(existing_contact_import)

        expect(existing_contact.reload.label_list).to contain_exactly('customer', 'vip', 'lead')
      end

      it 'matches labels case-insensitively and stores lowercase labels' do
        data_with_uppercase_labels = [
          %w[id name email phone_number labels],
          ['1', 'Case User', 'case@example.com', '+918080808087', 'VIP,Customer']
        ]
        uppercase_import = create(:data_import, account: labels_data_import.account,
                                                import_file: generate_csv_file(data_with_uppercase_labels))

        described_class.perform_now(uppercase_import)

        contact = Contact.from_email('case@example.com')
        expect(contact.label_list).to contain_exactly('vip', 'customer')
      end

      it 'deduplicates repeated labels in a row' do
        data_with_duplicate_labels = [
          %w[id name email phone_number labels],
          ['1', 'Duplicate User', 'duplicate@example.com', '+918080808088', 'vip,vip']
        ]
        duplicate_import = create(:data_import, account: labels_data_import.account,
                                                import_file: generate_csv_file(data_with_duplicate_labels))

        described_class.perform_now(duplicate_import)

        contact = Contact.from_email('duplicate@example.com')
        expect(contact.label_list).to contain_exactly('vip')
      end

      it 'merges labels from duplicate rows that resolve to the same contact' do
        data_with_duplicate_contact = [
          %w[id name email phone_number labels],
          ['1', 'Duplicate User', 'duplicate-contact@example.com', '+918080808089', 'customer'],
          ['2', 'Duplicate User', 'duplicate-contact@example.com', '+918080808089', 'vip']
        ]
        duplicate_contact_import = create(:data_import, account: labels_data_import.account,
                                                        import_file: generate_csv_file(data_with_duplicate_contact))

        described_class.perform_now(duplicate_contact_import)

        contact = Contact.from_email('duplicate-contact@example.com')
        expect(contact.label_list).to contain_exactly('customer', 'vip')
      end

      it 'does not dispatch contact update events when applying labels' do
        allow(Rails.configuration.dispatcher).to receive(:dispatch)

        described_class.perform_now(labels_data_import)

        expect(Rails.configuration.dispatcher).not_to have_received(:dispatch).with(Events::Types::CONTACT_UPDATED, anything, anything)
      end

      it 'marks the import as failed when label application raises an error' do
        failing_import = create(:data_import, account: labels_data_import.account, import_file: generate_csv_file(data_with_labels))
        data_import_job = described_class.new
        allow(data_import_job).to receive(:add_labels_without_update_event).and_raise(StandardError, 'Label application failed')

        data_import_job.perform(failing_import)

        expect(failing_import.reload).to be_failed
        expect(failing_import.processing_errors).to eq('Label application failed')
      end

      it 'rejects rows with labels that do not exist in the account' do
        data_with_unknown_labels = [
          %w[id name email phone_number labels],
          ['1', 'Unknown Label User', 'unknownlabel@example.com', '+918080808084', 'vip,unknown_label']
        ]

        unknown_label_import = create(:data_import, import_file: generate_csv_file(data_with_unknown_labels))
        create(:label, account: unknown_label_import.account, title: 'vip')

        described_class.perform_now(unknown_label_import)

        expect(Contact.from_email('unknownlabel@example.com')).to be_nil
        expect(unknown_label_import.reload.failed_records).to be_attached
        expect(unknown_label_import.failed_records.download).to include('Unknown labels: unknown_label')
      end

      it 'does not update an existing contact when the row has unknown labels' do
        existing_contact = create(:contact,
                                  account: labels_data_import.account,
                                  email: 'existing@example.com',
                                  phone_number: '+918080808085',
                                  name: 'Existing Name')
        data_with_unknown_labels = [
          %w[id name email phone_number labels],
          ['1', 'Updated Name', existing_contact.email, '+918080808086', 'vip,unknown_label']
        ]

        unknown_label_import = create(:data_import, account: labels_data_import.account,
                                                    import_file: generate_csv_file(data_with_unknown_labels))

        described_class.perform_now(unknown_label_import)

        expect(existing_contact.reload.name).to eq('Existing Name')
        expect(existing_contact.phone_number).to eq('+918080808085')
        expect(unknown_label_import.reload.failed_records).to be_attached
        expect(unknown_label_import.failed_records.download).to include('Unknown labels: unknown_label')
      end
    end
  end
end
