require 'rails_helper'

RSpec.describe 'Z-API webhook URL rotation API', type: :request do
  let(:account) { create(:account) }
  let(:administrator) { create(:user, account: account, role: :administrator) }
  let(:channel) do
    create(:channel_whatsapp, account: account, provider: 'zapi', sync_templates: false, validate_provider_config: false).tap do |zapi|
      zapi.provider_config = zapi.provider_config.merge('instance_id' => 'inst-1', 'token' => 'tok', 'webhook_verify_token' => 'leaked')
      zapi.save!(validate: false)
    end
  end
  let(:url) { "/api/v1/accounts/#{account.id}/whatsapp/zapi/#{channel.inbox.id}/rotate_webhook_url" }
  let(:update_webhooks_url) { "#{Whatsapp::Providers::WhatsappZapiService::API_BASE_PATH}/instances/inst-1/token/tok/update-every-webhooks" }

  it 'gives the inbox a new webhook URL' do
    stub_request(:put, update_webhooks_url).to_return(status: 200)

    post url, headers: administrator.create_new_auth_token, as: :json

    expect(response).to have_http_status(:ok)
    expect(channel.reload.provider_config['webhook_verify_token']).not_to eq('leaked')
  end

  it 'answers 422 when Z-API does not take the new URL' do
    stub_request(:put, update_webhooks_url).to_return(status: 400, body: 'error message')
    allow(Rails.logger).to receive(:error)

    post url, headers: administrator.create_new_auth_token, as: :json

    expect(response).to have_http_status(:unprocessable_entity)
  end

  it 'is only for administrators' do
    agent = create(:user, account: account, role: :agent)
    create(:inbox_member, user: agent, inbox: channel.inbox)

    post url, headers: agent.create_new_auth_token, as: :json

    expect(response).to have_http_status(:unauthorized)
    expect(channel.reload.provider_config['webhook_verify_token']).to eq('leaked')
  end

  it 'answers 404 for an inbox that is not Z-API' do
    other = create(:channel_whatsapp, account: account, provider: 'baileys', sync_templates: false, validate_provider_config: false)

    post "/api/v1/accounts/#{account.id}/whatsapp/zapi/#{other.inbox.id}/rotate_webhook_url", headers: administrator.create_new_auth_token, as: :json

    expect(response).to have_http_status(:not_found)
  end
end
