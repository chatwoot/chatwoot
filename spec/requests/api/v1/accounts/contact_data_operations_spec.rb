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

  it 'bounds export history and continues from the oldest displayed ID when new exports arrive' do
    options = { name: 'Export', export_options: { column_names: ['name'] } }
    exports = Array.new(26) { account.data_exports.create!(options) }
    create(:account).data_exports.create!(options)

    get "#{base_url}/data_exports", headers: headers
    first_page = response.parsed_body
    expect(first_page['payload'].pluck('id')).to eq(exports.last(25).reverse.map(&:id))
    expect(first_page['has_more']).to be(true)

    account.data_exports.create!(options)
    get "#{base_url}/data_exports", params: { before_id: first_page['payload'].last['id'] }, headers: headers
    expect(response.parsed_body['payload'].pluck('id')).to eq([exports.first.id])
    expect(response.parsed_body['has_more']).to be(false)
  end

  it 'rejects an invalid export history cursor' do
    get "#{base_url}/data_exports", params: { before_id: 'all' }, headers: headers
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it 'creates a tracked export and returns its selection' do
    expect do
      post "#{base_url}/data_exports", headers: headers, params: { column_names: %w[email name], scope_name: 'All contacts' }, as: :json
    end.to have_enqueued_job(DataExports::ContactsJob)
    expect(response).to have_http_status(:ok)
    expect(response).to conform_schema(200)
    expect(response.parsed_body['export_options']).to include('column_names' => %w[email name])
  end

  it 'uses body options even when the query string contains conflicting export options' do
    query = { column_names: ['phone_number'], scope_name: 'Query scope' }.to_query
    options = { column_names: %w[email name], scope_name: 'Body scope' }

    post "#{base_url}/data_exports?#{query}", headers: headers, params: options, as: :json

    expect(response).to have_http_status(:ok)
    expect(account.data_exports.last.export_options).to eq(options.stringify_keys)
  end

  it 'ignores query-only export options and uses the defaults for an empty body' do
    post "#{base_url}/data_exports?label=unavailable&scope_name=Query&unexpected=true", headers: headers, params: {}, as: :json

    expect(response).to have_http_status(:ok)
    expect(account.data_exports.last.export_options).to eq('column_names' => %w[id name email phone_number labels])
  end

  it 'rejects unknown options in the request body before queuing an export' do
    expect do
      post "#{base_url}/data_exports", headers: headers, params: { unexpected: true }, as: :json
    end.not_to have_enqueued_job(DataExports::ContactsJob)

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response).not_to conform_request_schema
    expect(response.parsed_body['message']).to eq('Unsupported export options: unexpected.')
    expect(account.data_exports).to be_empty
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

  it 'keeps existing Contacts filtering behavior while restricting export text values' do
    contact = create(:contact, account: account, name: '123', email: 'person@example.com')
    filter = { attribute_key: 'name', filter_operator: 'equal_to', values: [123], query_operator: nil }

    post "#{base_url}/contacts/filter", headers: headers, params: { payload: [filter] }, as: :json
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body['payload'].pluck('id')).to eq([contact.id])

    post "#{base_url}/data_exports", headers: headers, params: { payload: [filter] }, as: :json
    expect(response).to have_http_status(:unprocessable_entity)
    expect(account.data_exports).to be_empty
  end

  it 'continues accepting boolean and numeric custom attribute export filters' do
    create(:custom_attribute_definition, account: account, attribute_model: :contact_attribute,
                                         attribute_key: 'score', attribute_display_type: :number)
    filters = [
      { attribute_key: 'blocked', filter_operator: 'equal_to', values: [false], query_operator: 'AND' },
      { attribute_key: 'score', filter_operator: 'is_greater_than', values: [10], attribute_model: 'custom_attributes',
        custom_attribute_type: 'contact_attribute', query_operator: nil }
    ]
    post "#{base_url}/data_exports", headers: headers, params: { payload: filters }, as: :json
    expect(response).to have_http_status(:ok)
    expect(account.data_exports.last.export_options['payload'].last['values']).to eq([10])
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
