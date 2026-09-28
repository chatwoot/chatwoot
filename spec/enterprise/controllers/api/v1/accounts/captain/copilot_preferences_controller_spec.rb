require 'rails_helper'

RSpec.describe 'Api::V1::Accounts::Captain::CopilotPreferences', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:path) { "/api/v1/accounts/#{account.id}/captain/preferences" }

  def json_response
    JSON.parse(response.body, symbolize_names: true)
  end

  it 'includes assistant knowledge tools with the existing selection when no override is saved' do
    assistant = create(:captain_assistant, account: account)

    get path, headers: admin.create_new_auth_token, as: :json
    expect(json_response[:copilot_assistant_id]).to be_nil
    expect(json_response[:copilot_tools]).to include(name: 'search_documentation', available: true)

    account.update!(copilot_assistant_id: assistant.id)
    get path, headers: admin.create_new_auth_token, as: :json
    expect(json_response[:copilot_tools]).to include(name: 'search_documentation', available: true)
  end

  it 'saves an assistant choice and can return to the existing selection' do
    assistant = create(:captain_assistant, account: account)

    put path, headers: admin.create_new_auth_token,
              params: { copilot_assistant_id: assistant.id }, as: :json
    expect(response).to have_http_status(:success)
    expect(json_response).to include(copilot_assistant_id: assistant.id)

    put path, headers: admin.create_new_auth_token,
              params: { copilot_assistant_id: nil }, as: :json
    expect(response).to have_http_status(:success)
    expect(json_response).to include(copilot_assistant_id: nil)
  end

  it 'saves the Copilot choice when an older model setting is invalid' do
    # rubocop:disable Rails/SkipsModelValidations
    account.update_column(:settings, account.settings.merge('captain_models' => { 'assistant' => 'gpt-5.6-luna' }))
    # rubocop:enable Rails/SkipsModelValidations

    put path, headers: admin.create_new_auth_token,
              params: { copilot_assistant_id: create(:captain_assistant, account: account).id }, as: :json

    expect(response).to have_http_status(:success)
    expect(account.reload.copilot_assistant_id).to be_present
  end

  it 'rejects an assistant from another account' do
    assistant = create(:captain_assistant)

    put path, headers: admin.create_new_auth_token,
              params: { copilot_assistant_id: assistant.id }, as: :json

    expect(response).to have_http_status(:not_found)
  end
end
