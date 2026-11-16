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

  context 'when ordinary CSV columns update custom attributes' do
    let(:csv) { "name,email,row_number,tier,notes\nUpdated,existing@example.com,customer-42,,New note\n" }

    it 'preserves row_number and skips blank custom attribute cells without emitting contact events' do
      existing = create(:contact, account: account, email: 'existing@example.com',
                                  custom_attributes: { tier: 'gold', notes: 'Old note', subscribed: false })
      data_import
      allow(Rails.configuration.dispatcher).to receive(:dispatch)

      DataImports::Csv::PreparationJob.perform_now(data_import, run_id)
      importer.import_contacts_page
      importer.finish!

      expect(existing.reload.custom_attributes).to eq('row_number' => 'customer-42', 'tier' => 'gold',
                                                      'notes' => 'New note', 'subscribed' => false)
      expect(data_import.items.first.metadata['row_number']).to eq(1)
      expect(data_import.reload).to be_completed
      expect(Rails.configuration.dispatcher).not_to have_received(:dispatch).with(Events::Types::CONTACT_UPDATED, anything, anything)
    end
  end

  context 'when publishing rejected rows' do
    before do
      DataImports::Csv::PreparationJob.perform_now(data_import, run_id)
      importer.import_contacts_page
    end

    it 'uploads before locking the import and attaches the file on completion' do
      locked = false
      allow(data_import).to receive(:with_lock).and_wrap_original do |method, &block|
        locked = true
        method.call(&block)
      ensure
        locked = false
      end
      allow(ActiveStorage::Blob).to receive(:create_and_upload!).and_wrap_original do |method, **args|
        expect(locked).to be(false)
        method.call(**args)
      end

      importer.finish!

      expect(data_import.reload).to be_completed_with_errors
      expect(data_import.failed_records).to be_attached
    end

    it 'does not publish an uploaded file if the import was abandoned during upload' do
      blob = nil
      allow(ActiveStorage::Blob).to receive(:create_and_upload!).and_wrap_original do |method, **args|
        blob = method.call(**args)
        DataImport.find(data_import.id).update!(status: :abandoned, abandoned_at: Time.current)
        blob
      end

      expect { importer.finish! }.to have_enqueued_job(ActiveStorage::PurgeJob)
      expect(data_import.reload).to be_abandoned
      expect(data_import.failed_records).not_to be_attached
      expect(blob.attachments).to be_empty
      expect(DataImports::Csv::NotificationJob).not_to have_been_enqueued
    end

    it 'does not let a previous run attach a file after a restart during upload' do
      allow(ActiveStorage::Blob).to receive(:create_and_upload!).and_wrap_original do |method, **args|
        blob = method.call(**args)
        current = DataImport.find(data_import.id)
        current.update!(source_metadata: current.source_metadata.merge('active_import_run_id' => 'replacement'))
        blob
      end

      expect { importer.finish! }.to have_enqueued_job(ActiveStorage::PurgeJob)
      expect(data_import.reload).to be_processing
      expect(data_import.failed_records).not_to be_attached
      expect(DataImports::Csv::NotificationJob).not_to have_been_enqueued
    end

    it 'retains the uploaded blob for cleanup when completion rolls back' do
      blob = nil
      allow(ActiveStorage::Blob).to receive(:create_and_upload!).and_wrap_original do |method, **args|
        blob = method.call(**args)
      end
      allow(data_import).to receive(:with_lock).and_wrap_original do |method, &block|
        method.call(requires_new: true, &block)
      end
      allow(DataImports::Csv::NotificationJob).to receive(:perform_later).and_raise(IOError, 'Queue unavailable')

      expect { importer.finish! }.to raise_error(IOError, 'Queue unavailable')
      expect(data_import.reload).to be_processing
      expect(data_import.failed_records).not_to be_attached
      expect(ActiveStorage::Blob.exists?(blob.id)).to be(true)
      expect(ActiveStorage::PurgeJob).to have_been_enqueued.with(blob)
    end
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

  context 'when correcting rejected rows with spreadsheet-sensitive identities' do
    let(:identities) do
      [
        ['+external-42', nil],
        ["'+external-42", nil],
        ['@identifier-only', nil],
        ['-email-42', 'existing@example.com'],
        ['=plus-email', '+jane@example.com'],
        ["''literal-42", nil]
      ]
    end
    let(:existing_contacts) do
      identities.map do |identifier, email|
        create(:contact, account: account, identifier: identifier, email: email, phone_number: nil)
      end
    end
    let(:csv) do
      CSV.generate do |output|
        output << %w[name identifier email labels note -region '-literal]
        existing_contacts.each_with_index do |contact, index|
          output << ["Updated #{index}", contact.identifier, contact.email, 'missing', "'literal note", 'West', 'Literal header']
        end
      end
    end
    let(:corrected_import) do
      create(:data_import, account: account, source_provider: 'csv', source_type: 'file', import_types: ['contacts'],
                           source_metadata: { active_import_run_id: 'corrected' },
                           import_file: { io: StringIO.new(data_import.failed_records.download), filename: 'corrected.csv' })
    end
    let(:corrected_importer) { described_class.new(data_import: corrected_import, run_id: 'corrected') }

    it 'updates the original contacts without changing identifiers, emails, or literal apostrophes' do
      DataImports::Csv::PreparationJob.perform_now(data_import, run_id)
      importer.import_contacts_page
      importer.finish!
      create(:label, account: account, title: 'missing')

      expect do
        DataImports::Csv::PreparationJob.perform_now(corrected_import, 'corrected')
        corrected_importer.import_contacts_page
        corrected_importer.finish!
      end.not_to change(account.contacts, :count)

      expect(corrected_import.reload).to be_completed
      expect(corrected_import.stats['contacts']).to include('created' => 0, 'updated' => identities.size, 'failed' => 0)
      existing_contacts.each_with_index do |contact, index|
        expect(contact.reload.identifier).to eq(identities[index].first)
        expect(contact.email).to eq(identities[index].last)
        expect(contact.name).to eq("Updated #{index}")
        expect(contact.custom_attributes).to eq('note' => "'literal note", '-region' => 'West', "'-literal" => 'Literal header')
      end
    end

    it 'retains spreadsheet protection without accumulating escapes on repeated rejections' do
      DataImports::Csv::PreparationJob.perform_now(data_import, run_id)
      importer.import_contacts_page
      importer.finish!
      rejected = CSV.parse(data_import.failed_records.download, headers: true)
      expect(rejected.map { |row| row['identifier'] }).to eq(
        ["'+external-42", "''+external-42", "'@identifier-only", "'-email-42", "'=plus-email", "'''literal-42"]
      )
      expect(rejected[4]['email']).to eq("'+jane@example.com")

      DataImports::Csv::PreparationJob.perform_now(corrected_import, 'corrected')
      corrected_importer.import_contacts_page
      corrected_importer.finish!

      expect(corrected_import.reload).to be_completed_with_errors
      expect(corrected_import.failed_records.download).to eq(data_import.failed_records.download)
    end
  end
end
