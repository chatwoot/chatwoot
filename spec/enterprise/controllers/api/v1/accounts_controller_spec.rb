require 'rails_helper'
require 'base64'

RSpec.describe 'Enterprise Accounts API', type: :request do
  describe 'POST /api/v1/accounts' do
    let(:email) { Faker::Internet.email }
    let(:user_full_name) { Faker::Name.name_with_middle }
    let(:first_touch) do
      { source: 'x', source_type: 'paid_social', utm_source: 'x', utm_medium: 'paid_social', utm_campaign: 'x-pilot-nov',
        utm_content: 'creative-a', twclid: 'x-click-1', captured_at: '2026-11-05T10:00:00.000Z' }
    end
    let(:first_touch_cookie) { Base64.urlsafe_encode64(first_touch.to_json, padding: false) }
    let(:last_touch_cookie) { Base64.urlsafe_encode64({ source: 'github', source_type: 'referral' }.to_json, padding: false) }
    let(:attribution_cookie_header) do
      {
        'Cookie' => [
          "#{Internal::Accounts::MarketingAttributionService::FIRST_TOUCH_COOKIE}=#{first_touch_cookie}",
          "#{Internal::Accounts::MarketingAttributionService::LAST_TOUCH_COOKIE}=#{last_touch_cookie}"
        ].join('; ')
      }
    end

    before do
      allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(true)
    end

    it 'records marketing attribution for unauthenticated signup requests' do
      account_builder = double
      account = create(:account)
      user = create(:user, email: email, account: account, name: user_full_name)

      allow(AccountBuilder).to receive(:new).and_return(account_builder)
      allow(account_builder).to receive(:perform).and_return([user, account])

      expect do
        with_modified_env ENABLE_ACCOUNT_SIGNUP: 'true' do
          post api_v1_accounts_url,
               params: {
                 account_name: 'test',
                 email: email,
                 user: nil,
                 locale: nil,
                 user_full_name: user_full_name,
                 password: 'Password1!'
               },
               headers: attribution_cookie_header,
               as: :json
        end
      end.to have_enqueued_job(Internal::Accounts::MarketingConversionTrackingJob)
        .with(account.id, 'cloud_signup', account.created_at)

      attribution = account.reload.internal_attributes['marketing_attribution']
      expect(attribution['captured_from']).to eq('cookie')
      expect(attribution['first_touch']).to eq(first_touch.stringify_keys)
      expect(attribution['last_touch']).to include('source' => 'github', 'source_type' => 'referral')
    end

    it 'does not record attribution or send conversions when the signup fails' do
      account_builder = double
      allow(AccountBuilder).to receive(:new).and_return(account_builder)
      allow(account_builder).to receive(:perform).and_return([nil, nil])

      expect do
        with_modified_env ENABLE_ACCOUNT_SIGNUP: 'true' do
          post api_v1_accounts_url,
               params: { account_name: 'test', email: email, user_full_name: user_full_name, password: 'Password1!' },
               headers: attribution_cookie_header,
               as: :json
        end
      end.not_to have_enqueued_job(Internal::Accounts::MarketingConversionTrackingJob)

      expect(response).to have_http_status(:forbidden)
    end

    it 'does not record marketing attribution for authenticated add-workspace requests' do
      existing_user = create(:user, password: 'Password1!')

      expect do
        with_modified_env ENABLE_ACCOUNT_SIGNUP: 'true' do
          post api_v1_accounts_url,
               params: { account_name: 'Second Account', email: existing_user.email,
                         user_full_name: existing_user.name, password: 'Password1!' },
               headers: existing_user.create_new_auth_token.merge(attribution_cookie_header),
               as: :json
        end
      end.not_to have_enqueued_job(Internal::Accounts::MarketingConversionTrackingJob)

      account = Account.find(response.parsed_body.dig('data', 'account_id'))
      expect(account.internal_attributes).not_to include('marketing_attribution')
    end
  end

  describe 'GET /api/v1/accounts/{account.id}' do
    let(:account) { create(:account) }
    let(:admin) { create(:user, account: account, role: :administrator) }

    before do
      Redis::Alfred.set(Redis::Alfred::LATEST_CHATWOOT_VERSION, '4.16.1')
    end

    it 'hides the latest chatwoot version on cloud' do
      allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(true)

      get "/api/v1/accounts/#{account.id}",
          headers: admin.create_new_auth_token,
          as: :json

      expect(response.parsed_body['latest_chatwoot_version']).to be_nil
    end

    it 'exposes the latest chatwoot version on self-hosted enterprise' do
      allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(false)

      get "/api/v1/accounts/#{account.id}",
          headers: admin.create_new_auth_token,
          as: :json

      expect(response.parsed_body['latest_chatwoot_version']).to eq('4.16.1')
    end
  end

  describe 'PATCH /api/v1/accounts/{account.id}' do
    let(:account) { create(:account) }
    let(:admin) { create(:user, account: account, role: :administrator) }

    it 'keeps the billing fields the account show response returns' do
      allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(false)
      InstallationConfig.create!(name: 'INSTALLATION_SUBSCRIPTION_STATUS', value: 'past_due', locked: true)

      patch "/api/v1/accounts/#{account.id}",
            params: { name: 'Renamed' },
            headers: admin.create_new_auth_token,
            as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body).to include('billing_provider', 'subscribed_features')
      expect(response.parsed_body['installation_subscription_status']).to eq('past_due')
    end
  end
end
