require 'rails_helper'

RSpec.describe 'CRM Google conversion feed token API', type: :request do
  around do |example|
    previous_value = ENV.fetch('CRM_KANBAN_ENABLED', nil)
    ENV['CRM_KANBAN_ENABLED'] = 'true'
    example.run
  ensure
    previous_value.nil? ? ENV.delete('CRM_KANBAN_ENABLED') : ENV['CRM_KANBAN_ENABLED'] = previous_value
  end

  let(:account_and_user) { create_account_and_user }
  let(:account) { account_and_user.first }
  let(:user) { account_and_user.last }

  it 'generates a strong account token on demand and returns a scheduled feed URL' do
    post "/api/v1/accounts/#{account.id}/crm/google_conversion_feed", headers: auth_headers(user)

    token = response.parsed_body['token']
    expect(response).to have_http_status(:created)
    expect(token.length).to be >= 43
    expect(account.reload.custom_attributes['google_feed_token']).to eq(token)
    expect(response.parsed_body['url']).to end_with("/google_conversions/#{token}.csv")
  end

  it 'reuses the existing token instead of rotating the feed URL' do
    account.update!(custom_attributes: account.custom_attributes.merge('google_feed_token' => 'existing-token'))

    post "/api/v1/accounts/#{account.id}/crm/google_conversion_feed", headers: auth_headers(user)

    expect(response.parsed_body['token']).to eq('existing-token')
  end

  it 'rejects an unauthenticated request' do
    post "/api/v1/accounts/#{account.id}/crm/google_conversion_feed"

    expect(response).to have_http_status(:unauthorized)
  end
end
