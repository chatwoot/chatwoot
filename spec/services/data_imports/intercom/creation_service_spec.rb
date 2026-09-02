require 'rails_helper'

RSpec.describe DataImports::Intercom::CreationService do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:validator) { instance_double(DataImports::Intercom::CredentialsValidator, perform: { 'contacts' => 12 }) }

  before do
    allow(DataImports::Intercom::CredentialsValidator).to receive(:new).and_return(validator)
  end

  it 'validates and creates an import with its credentials and totals', :aggregate_failures do
    data_import = described_class.new(
      account: account,
      initiated_by: user,
      source_params: {
        name: 'Migration run',
        source_provider: 'intercom',
        access_token: ' intercom-token ',
        import_types: %w[contacts]
      }
    ).perform

    expect(data_import).to have_attributes(
      name: 'Migration run',
      source_type: 'api',
      source_provider: 'intercom',
      import_types: %w[contacts],
      access_token: 'intercom-token',
      initiated_by_id: user.id
    )
    expect(data_import.stats.dig('contacts', 'total')).to eq(12)
    expect(data_import.active_intercom_import_run_id).to be_present
  end

  it 'returns no import without validating when another import is active' do
    create(:data_import, :intercom, account: account, status: :processing)

    data_import = described_class.new(
      account: account,
      initiated_by: user,
      source_params: {
        name: 'Second run',
        source_provider: 'intercom',
        access_token: 'intercom-token'
      }
    ).perform

    expect(data_import).to be_nil
    expect(validator).not_to have_received(:perform)
  end
end
