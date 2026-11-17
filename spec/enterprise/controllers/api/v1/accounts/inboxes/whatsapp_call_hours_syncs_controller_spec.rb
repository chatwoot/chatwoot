require 'rails_helper'

RSpec.describe 'WhatsApp call hours sync API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:channel) do
    create(:channel_whatsapp, account: account, provider: 'whatsapp_cloud', validate_provider_config: false, sync_templates: false)
  end
  let(:inbox) { channel.inbox }
  let(:url) { "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/whatsapp_call_hours_sync" }

  before do
    account.enable_features!('channel_voice')
    channel.update!(provider_config: channel.provider_config.merge('calling_enabled' => true, 'business_hours_calls_enabled' => true))
    inbox.update!(working_hours_enabled: true)
    channel.record_call_hours_sync_failed('Temporary failure')
  end

  it 'lets administrators send the call hours to WhatsApp again' do
    expect do
      post url, headers: admin.create_new_auth_token, as: :json
    end.to have_enqueued_job(Whatsapp::SyncCallHoursJob).with(channel)

    expect(response).to have_http_status(:ok)
    expect(channel.reload).to have_attributes(call_hours_sync_status: 'pending', call_hours_sync_error: nil)
  end

  it 'does not let agents retry' do
    create(:inbox_member, user: agent, inbox: inbox)

    post url, headers: agent.create_new_auth_token, as: :json

    expect(response).to have_http_status(:unauthorized)
  end

  it 'refuses an inbox with calling off' do
    channel.update!(provider_config: channel.provider_config.merge('calling_enabled' => false))

    post url, headers: admin.create_new_auth_token, as: :json

    expect(response).to have_http_status(:unprocessable_entity)
  end

  it 'refuses an inbox from another account' do
    other_inbox = create(:inbox)

    post "/api/v1/accounts/#{account.id}/inboxes/#{other_inbox.id}/whatsapp_call_hours_sync", headers: admin.create_new_auth_token, as: :json

    expect(response).to have_http_status(:not_found)
  end
end
