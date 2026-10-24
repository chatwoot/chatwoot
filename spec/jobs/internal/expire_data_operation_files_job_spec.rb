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
end
