require 'rails_helper'

RSpec.describe DataImports::Intercom::RestartService do
  let(:account) { create(:account) }
  let(:data_import) { create(:data_import, :intercom, account: account, status: :abandoned, abandoned_at: 1.hour.ago) }

  it 'prepares a failed or abandoned import for another run', :aggregate_failures do
    data_import.import_errors.create!(error_code: 'StandardError', message: 'old error')
    previous_run_id = data_import.assign_active_intercom_import_run_id
    data_import.save!
    service = described_class.new(account: account, data_import: data_import)

    expect(service.perform).to eq(:enqueue)
    expect(service.data_import).to be_pending
    expect(service.data_import.abandoned_at).to be_nil
    expect(service.data_import.started_at).to be_nil
    expect(service.data_import.active_intercom_import_run_id).not_to eq(previous_run_id)
    expect(service.data_import.import_errors).to be_empty
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
