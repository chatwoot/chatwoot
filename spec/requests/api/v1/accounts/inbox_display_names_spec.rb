require 'rails_helper'

RSpec.describe 'Inbox display names', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:channel) { create(:channel_whatsapp, account: account, provider: 'whatsapp_cloud', validate_provider_config: false, sync_templates: false) }
  let(:inbox) { channel.inbox }
  let(:url) { "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/apply_display_name" }
  let(:health) do
    { status: 'CONNECTED', is_on_biz_app: false, new_display_name: 'Mona Assistant', new_name_status: 'APPROVED',
      official_business_account: { 'oba_status' => 'NOT_STARTED' } }
  end

  before do
    channel.provider_config['verification_pin'] = '123456'
    channel.save!(validate: false)
    allow(Whatsapp::HealthService).to receive(:new).and_return(instance_double(Whatsapp::HealthService, fetch_health_status: health))
  end

  it 'registers the approved name for an administrator without exposing credentials' do
    registration = stub_request(:post, %r{https://graph.facebook.com/v[\d.]+/#{channel.provider_config['phone_number_id']}/register})
                   .with(body: { messaging_product: 'whatsapp', pin: '123456' }.to_json)
                   .to_return(status: 200, body: { success: true }.to_json, headers: { 'Content-Type' => 'application/json' })

    post url, params: { display_name: 'Mona Assistant' }, headers: admin.create_new_auth_token, as: :json

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to eq('registration_submitted' => true)
    expect(registration).to have_been_requested.once
  end

  it 'requires authentication' do
    post url, params: { display_name: 'Mona Assistant' }, as: :json
    expect(response).to have_http_status(:unauthorized)
  end

  it 'rejects registration if the OBA status changed since the administrator viewed health' do
    channel.update!(phone_number_health: health.deep_stringify_keys)
    health[:official_business_account] = { 'oba_status' => 'APPROVED' }

    post url, params: { display_name: 'Mona Assistant' }, headers: admin.create_new_auth_token, as: :json

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body['error']).to include('contact Meta support')
    expect(a_request(:post, %r{/register})).not_to have_been_made
  end

  it 'rejects an assigned agent' do
    agent = create(:user, account: account, role: :agent)
    create(:inbox_member, user: agent, inbox: inbox)
    post url, params: { display_name: 'Mona Assistant' }, headers: agent.create_new_auth_token, as: :json
    expect(response).to have_http_status(:unauthorized)
  end

  it 'does not expose another account inbox' do
    other_admin = create(:user, account: create(:account), role: :administrator)
    post url, params: { display_name: 'Mona Assistant' }, headers: other_admin.create_new_auth_token, as: :json
    expect(response).to have_http_status(:unauthorized)
  end

  [nil, '', 123, true, ['Mona Assistant'], { name: 'Mona Assistant' }].each do |name|
    it "rejects malformed display_name #{name.inspect}" do
      post url, params: { display_name: name }, headers: admin.create_new_auth_token, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(Whatsapp::HealthService).not_to have_received(:new)
    end
  end

  it 'rejects an inbox belonging to another account' do
    other_inbox = create(:inbox)
    post "/api/v1/accounts/#{account.id}/inboxes/#{other_inbox.id}/apply_display_name",
         params: { display_name: 'Mona Assistant' }, headers: admin.create_new_auth_token, as: :json
    expect(response).to have_http_status(:not_found)
    expect(Whatsapp::HealthService).not_to have_received(:new)
  end

  it 'rejects channels other than WhatsApp Cloud API' do
    channel.provider = 'default'
    channel.save!(validate: false)
    post url, params: { display_name: 'Mona Assistant' }, headers: admin.create_new_auth_token, as: :json
    expect(response).to have_http_status(:unprocessable_entity)
    expect(Whatsapp::HealthService).not_to have_received(:new)
  end

  it 'returns Meta registration errors as 422' do
    stub_request(:post, %r{https://graph.facebook.com/v[\d.]+/#{channel.provider_config['phone_number_id']}/register})
      .to_return(status: 400, body: 'Meta registration error')
    post url, params: { display_name: 'Mona Assistant' }, headers: admin.create_new_auth_token, as: :json
    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body['error']).to include('Meta registration error')
  end
end
