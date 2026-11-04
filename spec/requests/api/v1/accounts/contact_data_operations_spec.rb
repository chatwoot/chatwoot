require 'rails_helper'

RSpec.describe 'Contact data operations API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:headers) { admin.create_new_auth_token }
  let(:base_url) { "/api/v1/accounts/#{account.id}" }

  before { account.disable_features!('data_import') }

  it 'uploads a CSV to storage and queues preparation without the integration flag' do
    file = fixture_file_upload(Rails.root.join('spec/assets/contacts.csv'), 'text/csv')
    expect do
      post "#{base_url}/data_imports", headers: headers, params: { source_provider: 'csv', import_file: file, import_types: ['contacts'] }
    end.to have_enqueued_job(DataImports::Csv::PreparationJob)
    expect(response).to have_http_status(:ok)
    record = account.data_imports.last
    expect(record.import_file.download).to eq(File.binread(Rails.root.join('spec/assets/contacts.csv')))
    expect(record).to be_csv_import
    expect(response.parsed_body['allowed_actions']).to include('abandon' => true)
  end

  it 'does not allow CSV conversations or invalid upload types' do
    post "#{base_url}/data_imports", headers: headers,
                                     params: { source_provider: 'csv', import_types: ['conversations'], import_file: 'not a file' }, as: :json
    expect(response).to have_http_status(:unprocessable_entity)
    expect(account.data_imports).to be_empty
  end

  it 'prevents an integration import without the integration feature' do
    post "#{base_url}/data_imports", headers: headers, params: { source_provider: 'intercom', access_token: 'test' }, as: :json
    expect(response).to have_http_status(:unauthorized)
  end

  it 'exposes only contact history while integrations are disabled' do
    contact_import = create(:data_import, account: account)
    create(:data_import, :intercom, account: account)
    get "#{base_url}/data_imports", headers: headers
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body['payload'].pluck('id')).to eq([contact_import.id])
    expect(response.parsed_body).to include('can_create_import' => false, 'integration_imports_enabled' => false)
  end

  it 'denies ordinary agents contact import history access' do
    agent = create(:user, account: account, role: :agent)
    agent_headers = agent.create_new_auth_token
    get "#{base_url}/data_imports", headers: agent_headers
    expect(response).to have_http_status(:unauthorized)
  end
end
