require 'rails_helper'

RSpec.describe 'WhatsApp business management token API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:channel) do
    create(:channel_whatsapp, account: account, provider: 'whatsapp_cloud', sync_templates: false, validate_provider_config: false)
  end
  let(:inbox) { channel.inbox }
  let(:service) { instance_double(Whatsapp::BusinessManagementTokenService, update!: true) }

  before do
    allow(Whatsapp::BusinessManagementTokenService).to receive(:new).with(channel).and_return(service)
  end

  it 'allows an administrator to validate and update the token' do
    put "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/whatsapp_business_management_token",
        headers: admin.create_new_auth_token,
        params: { business_management_token: 'business-token' },
        as: :json

    expect(service).to have_received(:update!).with('business-token')
    expect(response).to have_http_status(:no_content)
  end

  it 'does not allow an agent to update the token' do
    put "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/whatsapp_business_management_token",
        headers: agent.create_new_auth_token,
        params: { business_management_token: 'business-token' },
        as: :json

    expect(service).not_to have_received(:update!)
    expect(response).to have_http_status(:unauthorized)
  end

  it 'returns a consistent validation error response' do
    allow(service).to receive(:update!).and_raise(ArgumentError, 'Invalid token')

    put "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/whatsapp_business_management_token",
        headers: admin.create_new_auth_token,
        params: { business_management_token: 'business-token' },
        as: :json

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body).to eq('error' => 'Invalid token', 'message' => 'Invalid token')
  end
end
