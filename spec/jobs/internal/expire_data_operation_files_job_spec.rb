require 'rails_helper'

RSpec.describe Internal::ExpireDataOperationFilesJob do
  it 'removes terminal CSV artifacts and staged personal data while keeping history' do
    record = create(:data_import, source_provider: 'csv', source_type: 'file', import_types: ['contacts'],
                                  status: :completed, updated_at: 31.days.ago)
    record.items.create!(source_provider: 'csv', source_object_type: 'contact', source_object_id: 'row:1', status: :imported,
                         metadata: { fields: { email: 'person@example.com' }, row_number: 1, outcome: 'created' })
    record.update!(updated_at: 31.days.ago)
    described_class.perform_now
    expect(record.reload.source_metadata['artifacts_expired_at']).to be_present
    expect(record.import_file).not_to be_attached
    expect(record.items.first.metadata).to eq('row_number' => 1, 'outcome' => 'created')
    expect(record).not_to be_source_available
  end

  it 'never expires active imports and exports' do
    record = create(:data_import, source_provider: 'csv', source_type: 'file', import_types: ['contacts'], updated_at: 31.days.ago)
    export = record.account.data_exports.create!(name: 'Running', export_options: { column_names: ['email'] }, updated_at: 31.days.ago)
    described_class.perform_now
    expect(record.reload.import_file).to be_attached
    expect(export.reload.artifacts_expired_at).to be_nil
  end

  context 'when cleaning up a large import' do
    let(:record) do
      create(:data_import, source_provider: 'csv', source_type: 'file', import_types: ['contacts'],
                           status: :failed, updated_at: 31.days.ago)
    end
    let!(:items) do
      Array.new(3) do |index|
        item = record.items.create!(source_provider: 'csv', source_object_type: 'contact', source_object_id: "row:#{index}", status: :failed,
                                    metadata: { fields: { email: 'invalid' }, row_number: index }, last_error_message: 'Invalid email')
        record.import_errors.create!(data_import_item: item, error_code: 'InvalidCsv', message: 'Invalid email')
        item
      end
    end

    before do
      stub_const('Internal::ExpireDataOperationFilesJob::CLEANUP_BATCH_SIZE', 2)
      record.update!(updated_at: 31.days.ago)
    end

    it 'bounds row and error cleanup without holding the import transaction open', :aggregate_failures do
      writes = []
      transaction_depth = ActiveRecord::Base.connection.open_transactions
      subscriber = lambda do |event|
        sql = event.payload[:sql]
        next unless sql.start_with?('UPDATE "data_import_items"', 'DELETE FROM "data_import_errors"')

        writes << sql
        expect(ActiveRecord::Base.connection.open_transactions).to eq(transaction_depth)
        expect(record.reload).not_to be_source_available
        expect(DataImports::RestartService.new(account: record.account, data_import: record).perform).to eq(:access_token_missing)
      end

      ActiveSupport::Notifications.subscribed(subscriber, 'sql.active_record') { described_class.perform_now }

      expect(writes.count { |sql| sql.start_with?('UPDATE') }).to eq(2)
      expect(writes.count { |sql| sql.start_with?('DELETE') }).to eq(2)
      expect(record.items.order(:id).pluck(:metadata)).to eq([{ 'row_number' => 0 }, { 'row_number' => 1 }, { 'row_number' => 2 }])
      expect(record.import_errors).to be_empty
      expect(record.reload.source_metadata).not_to have_key('artifacts_cleanup_pending')
    end

    it 'retries unfinished batches after expiry without restoring source access', :aggregate_failures do
      updates = 0
      allow(DataImportItem.connection).to receive(:exec_update).and_wrap_original do |method, *args|
        if args[1] == 'DataImportItem Update All'
          updates += 1
          raise ActiveRecord::StatementInvalid, 'Interrupted cleanup' if updates == 2
        end
        method.call(*args)
      end

      expect { described_class.perform_now }.to raise_error(ActiveRecord::StatementInvalid, 'Interrupted cleanup')
      expect(items.first.reload.metadata).not_to have_key('fields')
      expect(items.last.reload.metadata).to have_key('fields')
      expired_at = record.reload.source_metadata.fetch('artifacts_expired_at')
      expect(record.source_metadata['artifacts_cleanup_pending']).to be(true)
      expect(record).not_to be_source_available

      described_class.perform_now

      expect(record.items.order(:id).pluck(:metadata)).to eq([{ 'row_number' => 0 }, { 'row_number' => 1 }, { 'row_number' => 2 }])
      expect(record.items.pluck(:last_error_message)).to all(be_nil)
      expect(record.import_errors).to be_empty
      expect(record.reload.source_metadata.fetch('artifacts_expired_at')).to eq(expired_at)
      expect(record.source_metadata).not_to have_key('artifacts_cleanup_pending')
    end
  end

  it 'expires completed exports without deleting their history or saved selection' do
    account = create(:account)
    export = account.data_exports.create!(name: 'Done', status: :completed, completed_at: 31.days.ago,
                                          export_options: { column_names: ['email'] },
                                          export_file: { io: StringIO.new('email'), filename: 'contacts.csv' })
    described_class.perform_now
    expect(export.reload.artifacts_expired_at).to be_present
    expect(export.export_file).not_to be_attached
    expect(export.export_options).to eq('column_names' => ['email'])
  end

  it 'scrubs row and run errors and continues expiring subsequent imports and exports' do
    record = create(:data_import, source_provider: 'csv', source_type: 'file', import_types: ['contacts'],
                                  status: :completed_with_errors, completed_at: 31.days.ago, total_records: 1)
    item = record.items.create!(source_provider: 'csv', source_object_type: 'contact', source_object_id: 'row:1', status: :failed,
                                metadata: { fields: { email: 'invalid' }, row_number: 1 }, last_error_message: 'Invalid email')
    record.import_errors.create!(data_import_item: item, error_code: 'InvalidCsv', message: 'Invalid email', details: { kind: 'failed' })
    record.import_errors.create!(error_code: 'IOError', message: 'Unavailable', details: { kind: 'run_error' })
    later_import = create(:data_import, source_provider: 'csv', source_type: 'file', import_types: ['contacts'],
                                        status: :completed, completed_at: 31.days.ago)
    export = record.account.data_exports.create!(name: 'Old export', status: :completed, completed_at: 31.days.ago,
                                                 export_options: { column_names: ['email'] })

    described_class.perform_now

    expect(record.reload.source_metadata['artifacts_expired_at']).to be_present
    expect(record.import_errors).to be_empty
    expect(item.reload).to have_attributes(metadata: { 'row_number' => 1 }, last_error_message: nil, status: 'failed')
    expect(record.total_records).to eq(1)
    expect(later_import.reload.source_metadata['artifacts_expired_at']).to be_present
    expect(export.reload.artifacts_expired_at).to be_present
  end

  [nil, ''].each do |provider|
    context "with legacy contact imports whose provider is #{provider.inspect}" do
      it 'expires both files from old terminal imports while keeping recent and active imports' do
        terminal = create(:data_import, source_provider: provider, status: :failed, last_error_at: 31.days.ago,
                                        failed_records: { io: StringIO.new('email,errors'), filename: 'rejected.csv' })
        recent = create(:data_import, source_provider: provider, status: :completed, completed_at: 29.days.ago)
        active = create(:data_import, source_provider: provider, updated_at: 31.days.ago)

        described_class.perform_now

        expect(terminal.reload.import_file).not_to be_attached
        expect(terminal.failed_records).not_to be_attached
        expect(terminal.source_metadata['artifacts_expired_at']).to be_present
        expect(terminal).to be_failed
        expect(recent.reload.import_file).to be_attached
        expect(active.reload.import_file).to be_attached
      end
    end
  end
end
