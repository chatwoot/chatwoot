require 'rails_helper'

RSpec.describe 'Integration Hooks API with Captain', type: :request do
  it 'returns the same error for a foreign Captain inbox and a nonexistent inbox' do
    account = create(:account)
    admin = create(:user, account: account, role: :administrator)
    foreign_inbox = create(:inbox)
    assistant = create(:captain_assistant, account: foreign_inbox.account)
    create(:captain_inbox, inbox: foreign_inbox, captain_assistant: assistant)
    headers = admin.create_new_auth_token
    path = api_v1_account_integrations_hooks_url(account_id: account.id)
    hook_params = { app_id: 'dialogflow', settings: { project_id: 'test', credentials: {} } }

    get api_v1_account_inbox_url(account_id: account.id, id: foreign_inbox.id), headers: headers, as: :json
    expect(response).to have_http_status(:not_found)

    post path, params: { hook: hook_params.merge(inbox_id: foreign_inbox.id) }, headers: headers, as: :json
    expect(response).to have_http_status(:unprocessable_entity)
    foreign_response = response.parsed_body

    post path, params: { hook: hook_params.merge(inbox_id: foreign_inbox.id + 1) }, headers: headers, as: :json
    expect(response).to have_http_status(:unprocessable_entity)
    expect(foreign_response).to eq(response.parsed_body)
    expect(foreign_response.to_s).not_to include('Captain')
  end
end
