require 'rails_helper'

RSpec.describe DataImports::Intercom::RestartService do
  let(:account) { create(:account) }
  let(:data_import) { create(:data_import, :intercom, account: account, status: :abandoned, abandoned_at: 1.hour.ago) }

  it 'prepares a failed or abandoned import for another run', :aggregate_failures do
    data_import.update!(
      stats: {
        'contacts' => { 'imported' => 1, 'skipped' => 9, 'total' => 10 },
        'conversations' => { 'imported' => 2, 'skipped' => 8, 'total' => 10 },
        'messages' => { 'imported' => 3, 'skipped' => 7, 'total' => 10 },
        'errors' => { 'count' => 6 }
      }
    )
    data_import.import_errors.create!(error_code: 'StandardError', message: 'old run error')
    data_import.import_errors.create!(
      error_code: 'ContactFailed',
      message: 'old contact error',
      source_object_type: 'contact',
      details: { kind: 'failed' }
    )
    retained_skip_log = data_import.import_errors.create!(
      error_code: DataImports::Intercom::Importer::ALREADY_IMPORTED_ERROR_CODE,
      message: 'old skip log',
      source_object_type: 'contact',
      details: { kind: 'skipped' }
    )
    previous_run_id = data_import.assign_active_intercom_import_run_id
    data_import.save!
    service = described_class.new(account: account, data_import: data_import)

    expect(service.perform).to eq(:enqueue)
    expect(service.data_import).to be_pending
    expect(service.data_import.abandoned_at).to be_nil
    expect(service.data_import.started_at).to be_nil
    expect(service.data_import.active_intercom_import_run_id).not_to eq(previous_run_id)
    expect(service.data_import.import_errors).to contain_exactly(retained_skip_log)
    expect(service.data_import.stats).to eq(
      'contacts' => { 'imported' => 1, 'skipped' => 1, 'total' => 10 },
      'conversations' => { 'imported' => 2, 'skipped' => 0, 'total' => 10 },
      'messages' => { 'imported' => 3, 'skipped' => 0, 'total' => 10 },
      'errors' => { 'count' => 0 }
    )
  end

  it 'returns the active import instead of restarting another import', :aggregate_failures do
    active_import = create(:data_import, :intercom, account: account, status: :processing)
    service = described_class.new(account: account, data_import: data_import)

    expect(service.perform).to eq(:render_show)
    expect(service.data_import).to eq(active_import)
    expect(data_import.reload).to be_abandoned
  end

  it 'does not restart when the stored access token is missing' do
    data_import.update!(access_token: nil)

    result = described_class.new(account: account, data_import: data_import).perform

    expect(result).to eq(:access_token_missing)
    expect(data_import.reload).to be_abandoned
  end
end
