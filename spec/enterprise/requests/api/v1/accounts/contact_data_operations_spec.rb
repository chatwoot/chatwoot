require 'rails_helper'

RSpec.describe 'Contact manager data operations', type: :request do
  let(:account) { create(:account) }
  let(:headers) { agent.create_new_auth_token }
  let(:agent) { create(:user) }
  let(:custom_role) { create(:custom_role, account: account, permissions: ['contact_manage']) }

  before { create(:account_user, user: agent, account: account, role: :agent, custom_role: custom_role) }

  it 'allows CSV and exports but hides integration imports' do
    account.enable_features!('data_import')
    create(:data_import, :intercom, account: account, status: :completed)
    get "/api/v1/accounts/#{account.id}/data_imports", headers: headers
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body['payload']).to be_empty
    expect(response.parsed_body['integration_imports_enabled']).to be(false)

    post "/api/v1/accounts/#{account.id}/data_exports", headers: headers, params: {}, as: :json
    expect(response).to have_http_status(:ok)

    file = fixture_file_upload(Rails.root.join('spec/assets/contacts.csv'), 'text/csv')
    post "/api/v1/accounts/#{account.id}/data_imports", headers: headers, params: { source_provider: 'csv', import_file: file }
    expect(response).to have_http_status(:ok)

    post "/api/v1/accounts/#{account.id}/data_imports", headers: headers,
                                                        params: { source_provider: 'intercom', access_token: 'test' }, as: :json
    expect(response).to have_http_status(:unauthorized)
  end
end
