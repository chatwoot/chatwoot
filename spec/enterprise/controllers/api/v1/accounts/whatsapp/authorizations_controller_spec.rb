require 'rails_helper'

RSpec.describe 'WhatsApp Embedded Signup during the Cloud trial', type: :request do
  let(:feature) { 'whatsapp_embedded_signup_inbox_creation' }
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:params) { { code: 'test_code', waba_id: 'test_waba_id', is_coexistence: true } }

  before do
    allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(true)
    account.disable_features!(feature)
  end

  it 'advertises Quick setup and allows Coexistence while the trial is active' do
    channel = create(:channel_whatsapp, account: account, validate_provider_config: false, sync_templates: false)
    embedded_signup = instance_double(Whatsapp::EmbeddedSignupService, perform: channel)

    allow(Whatsapp::EmbeddedSignupService).to receive(:new).with(account: account, params: params, inbox_id: nil).and_return(embedded_signup)

    get api_v1_account_url(account), headers: admin.create_new_auth_token, as: :json
    expect(response.parsed_body.dig('features', feature)).to be true

    post "/api/v1/accounts/#{account.id}/whatsapp/authorization", params: params, headers: admin.create_new_auth_token, as: :json
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to include('id' => channel.inbox.id, 'success' => true)
    expect(account.reload).not_to be_feature_enabled(feature)
  end

  it 'stops offering and authorizing Quick setup when a trial ends without the flag' do
    travel_to(account.created_at + 15.days, with_usec: true) do
      get api_v1_account_url(account), headers: admin.create_new_auth_token, as: :json
      expect(response.parsed_body.fetch('features')).not_to have_key(feature)

      expect(Whatsapp::EmbeddedSignupService).not_to receive(:new)
      post "/api/v1/accounts/#{account.id}/whatsapp/authorization", params: params, headers: admin.create_new_auth_token, as: :json
      expect(response).to have_http_status(:unauthorized)
    end
  end

  it 'uses the Shopify account flag for workspaces billed through Shopify' do
    shopify_account = create(:account, internal_attributes: { 'billing_provider' => 'shopify' })
    shopify_account.disable_features!(feature)
    shopify_admin = create(:user, account: shopify_account, role: :administrator)

    get api_v1_account_url(shopify_account), headers: shopify_admin.create_new_auth_token, as: :json
    expect(response.parsed_body.fetch('features')).not_to have_key(feature)
  end
end
