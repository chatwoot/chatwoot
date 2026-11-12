require 'rails_helper'

RSpec.describe 'Call callback permission API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:channel) do
    create(:channel_whatsapp, account: account, provider: 'whatsapp_cloud', validate_provider_config: false, sync_templates: false)
  end
  let(:provider_service) { instance_double(Whatsapp::Providers::WhatsappCloudService, update_callback_permission_status: true) }
  let(:url) { "/api/v1/accounts/#{account.id}/inboxes/#{channel.inbox.id}/call_callback_permission" }

  before do
    account.enable_features!('channel_voice')
    channel.update!(provider_config: channel.provider_config.merge('calling_enabled' => true))
    allow(Whatsapp::Providers::WhatsappCloudService).to receive(:new).and_return(provider_service)
  end

  it 'tells Meta and saves the setting' do
    patch url, headers: admin.create_new_auth_token, params: { callback_permission_enabled: true }, as: :json

    expect(response).to have_http_status(:ok)
    expect(provider_service).to have_received(:update_callback_permission_status).with('ENABLED')
    expect(channel.reload.callback_permission_enabled?).to be true
  end

  it 'keeps the setting when Meta refuses it' do
    allow(provider_service).to receive(:update_callback_permission_status).and_raise('Turn calling on first')

    patch url, headers: admin.create_new_auth_token, params: { callback_permission_enabled: true }, as: :json

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body['error']).to eq('Turn calling on first')
    expect(channel.reload.callback_permission_enabled?).to be false
  end

  it 'rejects a value that is not a boolean' do
    patch url, headers: admin.create_new_auth_token, params: { callback_permission_enabled: 'yes' }, as: :json

    expect(response).to have_http_status(:unprocessable_entity)
    expect(provider_service).not_to have_received(:update_callback_permission_status)
  end

  it 'does not let agents change it' do
    agent = create(:user, account: account, role: :agent)
    create(:inbox_member, inbox: channel.inbox, user: agent)

    patch url, headers: agent.create_new_auth_token, params: { callback_permission_enabled: true }, as: :json

    expect(response).to have_http_status(:unauthorized)
  end

  it 'is rejected while WhatsApp calling is off' do
    channel.update!(provider_config: channel.provider_config.merge('calling_enabled' => false))

    patch url, headers: admin.create_new_auth_token, params: { callback_permission_enabled: true }, as: :json

    expect(response).to have_http_status(:unprocessable_entity)
    expect(provider_service).not_to have_received(:update_callback_permission_status)
  end

  it 'is rejected for an inbox that is not WhatsApp' do
    patch "/api/v1/accounts/#{account.id}/inboxes/#{create(:inbox, account: account).id}/call_callback_permission",
          headers: admin.create_new_auth_token, params: { callback_permission_enabled: true }, as: :json

    expect(response).to have_http_status(:unprocessable_entity)
  end
end
