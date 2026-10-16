require 'rails_helper'

RSpec.describe DataImports::Csv::Importer do
  let(:account) { create(:account) }
  let(:run_id) { SecureRandom.uuid }
  let(:csv) do
    <<~CSV
      name,email,phone_number,labels,tier
      Updated,existing@example.com,,,gold
      New,new@example.com,+14155552671,vip,silver
      Rejected,invalid-email,,,bronze
    CSV
  end
  let(:data_import) do
    create(:data_import, account: account, source_provider: 'csv', source_type: 'file', import_types: ['contacts'],
                         source_metadata: { active_import_run_id: run_id },
                         import_file: { io: StringIO.new(csv), filename: 'contacts.csv', content_type: 'text/csv' })
  end
  let(:importer) { described_class.new(data_import: data_import, run_id: run_id) }

  it 'stages before writing, silently creates and updates, and records rejected rows', :aggregate_failures do
    existing = create(:contact, account: account, email: 'existing@example.com', custom_attributes: { retained: true })
    create(:label, account: account, title: 'vip')
    data_import
    allow(Rails.configuration.dispatcher).to receive(:dispatch)

    expect { DataImports::Csv::PreparationJob.perform_now(data_import, run_id) }.not_to change(Contact, :count)
    expect(data_import.reload.total_records).to eq(3)
    expect(data_import.items.pending.count).to eq(3)

    importer.import_contacts_page
    importer.finish!

    expect(existing.reload.name).to eq('Updated')
    expect(existing.custom_attributes).to include('retained' => true, 'tier' => 'gold')
    expect(account.contacts.find_by!(email: 'new@example.com').label_list).to eq(['vip'])
    expect(data_import.reload).to be_completed_with_errors
    expect(data_import.stats['contacts']).to include('created' => 1, 'updated' => 1, 'failed' => 1, 'processed' => 3, 'imported' => 2)
    expect(data_import.stats.dig('errors', 'count')).to eq(1)
    expect(data_import.failed_records.download).to include('Rejected,invalid-email', 'errors')
    expect(data_import.mappings).to be_empty
    expect(Rails.configuration.dispatcher).not_to have_received(:dispatch).with(Events::Types::CONTACT_CREATED, anything, anything)
    expect(Rails.configuration.dispatcher).not_to have_received(:dispatch).with(Events::Types::CONTACT_UPDATED, anything, anything)
  end

  context 'when the CSV has a structural error after a valid row' do
    let(:csv) { "name,email\nValid,valid@example.com\n\"unterminated" }

    it 'fails preparation without changing any contacts' do
      expect { DataImports::Csv::PreparationJob.perform_now(data_import, run_id) }.not_to change(Contact, :count)
      expect(data_import.reload).to be_failed
      expect(data_import.import_errors.last.message).to include('Unclosed quoted field')
    end
  end

  context 'when the CSV has a BOM, multiline fields, emoji, and invalid bytes' do
    let(:csv) { "\uFEFFname,email\n\"Hi 😄\nthere\",person@example.com\nBad\xFF,bad@example.com\n".b }

    it 'normalizes the encoding and counts logical records' do
      DataImports::Csv::PreparationJob.perform_now(data_import, run_id)
      importer.import_contacts_page
      importer.finish!
      expect(data_import.reload.total_records).to eq(2)
      expect(account.contacts.find_by!(email: 'person@example.com').name).to eq("Hi 😄\nthere")
      expect(account.contacts.find_by!(email: 'bad@example.com').name).to eq('Bad')
    end
  end

  it 'rejects conflicting identities without partially updating either contact' do
    first = create(:contact, account: account, email: 'first@example.com')
    second = create(:contact, account: account, identifier: 'second')
    data_import.import_file.attach(io: StringIO.new("name,email,identifier\nWrong,first@example.com,second\n"), filename: 'contacts.csv')
    DataImports::Csv::PreparationJob.perform_now(data_import, run_id)
    importer.import_contacts_page
    expect(data_import.items.failed.count).to eq(1)
    expect(first.reload.name).not_to eq('Wrong')
    expect(second.reload.email).not_to eq('first@example.com')
  end

  it 'does not overwrite successful rows when recovering after a failure or accepting a stale worker' do
    create(:label, account: account, title: 'vip')
    DataImports::Csv::PreparationJob.perform_now(data_import, run_id)
    importer.import_contacts_page
    contact = account.contacts.find_by!(email: 'new@example.com')
    contact.update!(name: 'Edited after import')
    importer.fail!(StandardError.new('worker failed'))

    restart = DataImports::RestartService.new(account: account, data_import: data_import)
    expect(restart.perform).to eq(:enqueue)
    importer.import_contacts_page
    importer.finish!
    expect(data_import.reload).to be_pending

    resumed = described_class.new(data_import: data_import, run_id: data_import.active_import_run_id)
    resumed.start!
    resumed.import_contacts_page
    resumed.finish!
    expect(contact.reload.name).to eq('Edited after import')
    expect(data_import.items.imported.pluck(:attempt_count)).to all(eq(1))
    expect(data_import.reload).to be_completed_with_errors
  end

  it 'does not publish completion if rejected-row storage fails' do
    DataImports::Csv::PreparationJob.perform_now(data_import, run_id)
    importer.import_contacts_page
    allow(ActiveStorage::Blob).to receive(:create_and_upload!).and_raise(IOError, 'Storage unavailable')
    expect { importer.finish! }.to raise_error(IOError)
    expect(data_import.reload).to be_processing
  end

  it 'allows a corrected rejected row with an escaped phone number to be imported again' do
    data_import.import_file.attach(io: StringIO.new("name,email,phone_number,labels\nJane,jane@example.com,+14155552671,missing\n"),
                                   filename: 'contacts.csv')
    DataImports::Csv::PreparationJob.perform_now(data_import, run_id)
    importer.import_contacts_page
    importer.finish!
    rejected = data_import.failed_records.download
    expect(rejected).to include("'+14155552671")
    create(:label, account: account, title: 'missing')
    corrected = create(:data_import, account: account, source_provider: 'csv', source_type: 'file', import_types: ['contacts'],
                                     source_metadata: { active_import_run_id: 'corrected' },
                                     import_file: { io: StringIO.new(rejected), filename: 'corrected.csv' })
    DataImports::Csv::PreparationJob.perform_now(corrected, 'corrected')
    corrected_importer = described_class.new(data_import: corrected, run_id: 'corrected')
    corrected_importer.import_contacts_page
    corrected_importer.finish!
    expect(corrected.reload).to be_completed
    expect(account.contacts.find_by!(email: 'jane@example.com').phone_number).to eq('+14155552671')
  end
end
