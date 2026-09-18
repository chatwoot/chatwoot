require 'rails_helper'
require 'base64'

RSpec.describe 'Enterprise Google OAuth attribution', type: :request do
  let(:email_validation_service) { instance_double(Account::SignUpEmailValidationService) }
  let(:email) { 'oauth-attribution@example.com' }
  let(:account_builder) { double }
  let(:account) { create(:account) }
  let(:first_touch_cookie) { encoded_cookie('source' => 'reddit', 'source_type' => 'paid_social') }
  let(:last_touch_cookie) { encoded_cookie('source' => 'github', 'source_type' => 'referral') }

  before do
    allow(ChatwootApp).to receive(:enterprise?).and_return(true)
    allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(true)
    allow(Account::SignUpEmailValidationService).to receive(:new).and_return(email_validation_service)
    allow(email_validation_service).to receive(:perform).and_return(true)
    allow(AccountBuilder).to receive(:new).and_return(account_builder)
    allow(account_builder).to receive(:perform) do
      [create(:user, email: email, account: account), account]
    end

    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: 'google',
      uid: '123545',
      info: {
        name: 'OAuth Attribution',
        email: email,
        image: 'https://example.com/image.jpg'
      }
    )
  end

  it 'records marketing attribution for Google OAuth signups' do
    cookies[Internal::Accounts::MarketingAttributionService::FIRST_TOUCH_COOKIE] = first_touch_cookie
    cookies[Internal::Accounts::MarketingAttributionService::LAST_TOUCH_COOKIE] = last_touch_cookie

    with_modified_env ENABLE_ACCOUNT_SIGNUP: 'true', FRONTEND_URL: 'http://www.example.com' do
      get '/omniauth/google_oauth2/callback'
      follow_redirect!
    end

    attribution = account.reload.internal_attributes['marketing_attribution']

    expect(attribution['captured_from']).to eq('cookie')
    expect(attribution['first_touch']).to include('source' => 'reddit', 'source_type' => 'paid_social')
    expect(attribution['last_touch']).to include('source' => 'github', 'source_type' => 'referral')
  end

  def encoded_cookie(payload)
    Base64.urlsafe_encode64(payload.to_json, padding: false)
  end
end
