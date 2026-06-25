require 'rails_helper'
require 'base64'

RSpec.describe 'Enterprise Accounts API', type: :request do
  describe 'POST /api/v1/accounts' do
    let(:email) { Faker::Internet.email }
    let(:user_full_name) { Faker::Name.name_with_middle }
    let(:first_touch_cookie) { Base64.urlsafe_encode64({ source: 'reddit', source_type: 'paid_social' }.to_json, padding: false) }
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
      expect(attribution['first_touch']).to include('source' => 'reddit', 'source_type' => 'paid_social')
      expect(attribution['last_touch']).to include('source' => 'github', 'source_type' => 'referral')
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
end
