require 'rails_helper'

RSpec.describe 'Shopify billing hook protection', type: :request do
  let(:account) do
    create(
      :account,
      internal_attributes: {
        'billing_provider' => 'shopify',
        'signup_source' => 'shopify'
      }
    )
  end
  let(:admin) { create(:user, account: account, role: :administrator) }
  let!(:hook) { create(:integrations_hook, :shopify, account: account, status: :enabled) }

  before do
    account.enable_features!('shopify_integration')
    allow(GlobalConfigService).to receive(:load)
      .with('ENABLE_SHOPIFY_INTEGRATION', 'false')
      .and_return(true)
  end

  it 'does not disable the billing-owned hook through the generic hooks API' do
    patch api_v1_account_integrations_hook_url(account_id: account.id, id: hook.id),
          params: { hook: { status: 'disabled' } },
          headers: admin.create_new_auth_token,
          as: :json

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body['error']).to eq('Shopify-billed integrations must be managed in Shopify')
    expect(hook.reload).to be_enabled
  end

  it 'does not delete the billing-owned hook through the generic hooks API' do
    delete api_v1_account_integrations_hook_url(account_id: account.id, id: hook.id),
           headers: admin.create_new_auth_token,
           as: :json

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body['error']).to eq('Shopify-billed integrations must be managed in Shopify')
    expect(Integrations::Hook.exists?(hook.id)).to be(true)
  end

  it 'does not delete the billing-owned hook through the Shopify API' do
    delete "/api/v1/accounts/#{account.id}/integrations/shopify",
           headers: admin.create_new_auth_token,
           as: :json

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body['error']).to eq('Shopify-billed integrations must be managed in Shopify')
    expect(Integrations::Hook.exists?(hook.id)).to be(true)
  end
end
