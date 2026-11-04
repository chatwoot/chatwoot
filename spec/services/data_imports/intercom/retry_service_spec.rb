require 'rails_helper'

RSpec.describe DataImports::Intercom::RetryService do
  let(:account) { create(:account) }
  let(:data_import) { create(:data_import, :intercom, account: account, status: :processing, started_at: 2.hours.ago) }

  before do
    account.enable_features!('data_import')
  end

  it 'prepares a stalled import for another run without clearing progress', :aggregate_failures do
    original_cursor = { 'contacts' => { 'completed' => true }, 'conversations' => { 'starting_after' => 'cursor-1' } }
    original_stats = { 'contacts' => { 'imported' => 10 }, 'conversations' => { 'imported' => 5 } }
    started_at = data_import.started_at
    error = data_import.import_errors.create!(error_code: 'MessageFailed', message: 'Timed out')
    data_import.update!(
      cursor: original_cursor,
      stats: original_stats,
      source_metadata: { DataImport::ACTIVE_INTERCOM_IMPORT_RUN_ID_KEY => 'previous-run' },
      updated_at: 16.minutes.ago
    )

    result = described_class.new(account: account, data_import: data_import).perform

    expect(result).to eq(:enqueue)
    expect(data_import.reload).to be_pending
    expect(data_import.started_at).to eq(started_at)
    expect(data_import.cursor).to eq(original_cursor)
    expect(data_import.stats).to eq(original_stats)
    expect(data_import.import_errors).to contain_exactly(error)
    expect(data_import.active_intercom_import_run_id).not_to eq('previous-run')
  end

  it 'does not retry an import that is still receiving updates' do
    result = described_class.new(account: account, data_import: data_import).perform

    expect(result).to eq(:not_stalled)
    expect(data_import.reload).to be_processing
  end

  it 'rechecks the import state after acquiring its row lock' do
    data_import.update!(updated_at: 16.minutes.ago)
    allow(data_import).to receive(:with_lock).and_wrap_original do |method, *args, &block|
      data_import.update!(status: :completed, completed_at: Time.current)
      method.call(*args, &block)
    end

    result = described_class.new(account: account, data_import: data_import).perform

    expect(result).to eq(:not_stalled)
    expect(data_import.reload).to be_completed
  end

  it 'does not retry while another Intercom import is active' do
    data_import.update!(updated_at: 16.minutes.ago)
    create(:data_import, :intercom, account: account, status: :processing)

    result = described_class.new(account: account, data_import: data_import).perform

    expect(result).to eq(:active_import_exists)
    expect(data_import.reload).to be_processing
  end

  it 'allows an active legacy import to continue alongside the retry' do
    data_import.update!(updated_at: 16.minutes.ago)
    create(:data_import, account: account, status: :processing)

    result = described_class.new(account: account, data_import: data_import).perform

    expect(result).to eq(:enqueue)
    expect(data_import.reload).to be_pending
  end

  it 'does not retry when the stored access key is unavailable' do
    data_import.update!(access_token: nil, updated_at: 16.minutes.ago)

    result = described_class.new(account: account, data_import: data_import).perform

    expect(result).to eq(:access_token_missing)
    expect(data_import.reload).to be_processing
  end
end
