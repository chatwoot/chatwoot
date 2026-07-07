require 'rails_helper'

RSpec.describe 'Autonomia prospecting settings API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, :administrator, account: account) }

  before do
    Autonomia::Prospecting::Config.enable_for!(account)
  end

  it 'updates Google settings without exposing the backend Places API key' do
    pipeline, stage = create_crm_pipeline(account: account, user: admin)

    patch "/api/v1/accounts/#{account.id}/autonomia/prospecting/settings",
          params: {
            settings: {
              provider: 'google_places',
              provider_enabled: true,
              default_limit: 10,
              max_results_per_search: 10,
              daily_limit: 3,
              monthly_limit: 10,
              cache_ttl_seconds: 600,
              default_crm_pipeline_id: pipeline.id,
              default_crm_stage_id: stage.id,
              google_places_api_key: 'server-secret-key',
              google_maps_browser_api_key: 'browser-restricted-key'
            }
          },
          headers: auth_headers(admin)

    expect(response).to have_http_status(:ok)
    payload = response.parsed_body['payload']
    expect(payload['provider']).to eq('google_places')
    expect(payload['has_google_places_api_key']).to be(true)
    expect(payload['daily_limit']).to eq(3)
    expect(payload['monthly_limit']).to eq(10)
    expect(payload['default_crm_pipeline_id']).to eq(pipeline.id)
    expect(payload['default_crm_stage_id']).to eq(stage.id)
    expect(payload.dig('usage', 'daily_used')).to eq(0)
    expect(payload).not_to have_key('google_places_api_key')
    expect(payload['has_google_maps_browser_api_key']).to be(true)
    expect(payload['google_maps_api_key']).to eq('browser-restricted-key')

    saved_setting = Autonomia::Prospecting::Setting.for_account(account)
    expect(saved_setting.google_places_api_key).to eq('server-secret-key')
    expect(saved_setting.google_maps_browser_api_key).to eq('browser-restricted-key')
  end

  it 'clears the stored Google keys explicitly' do
    setting = Autonomia::Prospecting::Setting.for_account(account)
    setting.update!(
      google_places_api_key: 'server-secret-key',
      google_maps_browser_api_key: 'browser-restricted-key'
    )

    patch "/api/v1/accounts/#{account.id}/autonomia/prospecting/settings",
          params: {
            settings: {
              clear_google_places_api_key: true,
              clear_google_maps_browser_api_key: true
            }
          },
          headers: auth_headers(admin)

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig('payload', 'has_google_places_api_key')).to be(false)
    expect(response.parsed_body.dig('payload', 'has_google_maps_browser_api_key')).to be(false)
    expect(response.parsed_body.dig('payload', 'google_maps_api_key')).to be_blank
    expect(setting.reload.google_places_api_key).to be_blank
    expect(setting.reload.google_maps_browser_api_key).to be_blank
  end

  def auth_headers(user)
    { 'api_access_token' => user.access_token.token }
  end
end
