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

  it 'creates a tracked export and returns its selection' do
    expect do
      post "#{base_url}/data_exports", headers: headers, params: { column_names: %w[email name], scope_name: 'All contacts' }, as: :json
    end.to have_enqueued_job(DataExports::ContactsJob)
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body['export_options']).to include('column_names' => %w[email name])
  end

  it 'rejects malformed filters instead of exporting all contacts' do
    post "#{base_url}/data_exports", headers: headers, params: { payload: { attribute_key: 'email' } }, as: :json
    expect(response).to have_http_status(:unprocessable_entity)
    expect(account.data_exports).to be_empty
  end

  it 'isolates export history and downloads by account' do
    other = create(:account)
    record = other.data_exports.create!(name: 'Other export', export_options: { column_names: ['email'] })
    get "#{base_url}/data_exports/#{record.id}", headers: headers
    expect(response).to have_http_status(:not_found)
    get "#{base_url}/data_exports/#{record.id}/download", headers: headers
    expect(response).to have_http_status(:not_found)
  end

  it 'rejects malformed blank labels instead of widening the scope' do
    post "#{base_url}/data_exports", headers: headers, params: { label: [] }, as: :json
    expect(response).to have_http_status(:unprocessable_entity)
    expect(account.data_exports).to be_empty
  end

  it 'rejects nested filter values at the request boundary' do
    filter = { attribute_key: 'email', filter_operator: 'contains', values: [{ value: 'example.com' }] }
    post "#{base_url}/data_exports", headers: headers, params: { payload: [filter] }, as: :json
    expect(response).to have_http_status(:unprocessable_entity)
    expect(account.data_exports).to be_empty
  end

  it 'rejects non-string values for text filters before creating an export' do
    %w[email phone_number country_code].each do |attribute|
      filter = { attribute_key: attribute, filter_operator: 'equal_to', values: [123] }
      post "#{base_url}/data_exports", headers: headers, params: { payload: [filter] }, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end
    filter = { attribute_key: 'email', filter_operator: 'contains', values: [false] }
    post "#{base_url}/data_exports", headers: headers, params: { payload: [filter] }, as: :json
    expect(response).to have_http_status(:unprocessable_entity)
    expect(account.data_exports).to be_empty
  end

  it 'returns a short-lived download URL only for a completed export' do
    record = DataExports::CreationService.new(account: account, initiated_by: admin, options: {}).perform
    get "#{base_url}/data_exports/#{record.id}/download", headers: headers
    expect(response).to have_http_status(:not_found)
    DataExports::ContactsJob.perform_now(record, record.active_run_id)
    get "#{base_url}/data_exports/#{record.id}/download", headers: headers
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body['download_url']).to include('/rails/active_storage/disk/')
  end

  it 'denies ordinary agents import, export, and history access' do
    agent = create(:user, account: account, role: :agent)
    agent_headers = agent.create_new_auth_token
    get "#{base_url}/data_exports", headers: agent_headers
    expect(response).to have_http_status(:unauthorized)
    get "#{base_url}/data_imports", headers: agent_headers
    expect(response).to have_http_status(:unauthorized)
    post "#{base_url}/data_exports", headers: agent_headers, params: {}, as: :json
    expect(response).to have_http_status(:unauthorized)
  end
end
