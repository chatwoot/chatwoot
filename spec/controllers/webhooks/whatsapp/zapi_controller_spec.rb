require 'rails_helper'

RSpec.describe 'Webhooks::Whatsapp::ZapiController', type: :request do
  let(:channel) do
    create(:channel_whatsapp, provider: 'zapi', sync_templates: false, validate_provider_config: false).tap do |zapi|
      zapi.provider_config = zapi.provider_config.merge('instance_id' => 'inst-1', 'webhook_verify_token' => 'zapi-token')
      zapi.save!(validate: false)
    end
  end

  before { allow(Webhooks::WhatsappEventsJob).to receive(:perform_later) }

  it 'queues the event for the inbox, without the token' do
    post "/webhooks/whatsapp/zapi/#{channel.id}/zapi-token", params: { type: 'ReceivedCallback', phone: '5511999999999' }, as: :json

    expect(response).to have_http_status(:ok)
    expect(Webhooks::WhatsappEventsJob).to have_received(:perform_later) do |args|
      expect(args).to include('phone_number' => channel.phone_number, 'type' => 'ReceivedCallback', 'phone' => '5511999999999')
      expect(args.keys).not_to include('webhook_token', 'channel_id')
    end
  end

  # The delivery proves Z-API is on this URL, even when its answer to the registration was lost.
  it 'confirms the new URL on the first delivery, closing the old one' do
    post "/webhooks/whatsapp/zapi/#{channel.id}/zapi-token", params: { type: 'ReceivedCallback', instanceId: 'inst-1' }, as: :json

    expect(channel.reload.provider_config['webhook_url_confirmed_for']).to eq('inst-1')
  end

  it 'does not confirm it for a delivery from an instance the inbox has left' do
    post "/webhooks/whatsapp/zapi/#{channel.id}/zapi-token", params: { type: 'ReceivedCallback', instanceId: 'old-instance' }, as: :json

    expect(channel.reload.provider_config).not_to have_key('webhook_url_confirmed_for')
  end

  # A Cloud payload makes the job pick the inbox from the body; this token speaks only for its own.
  it 'does not let the body pick another inbox' do
    post "/webhooks/whatsapp/zapi/#{channel.id}/zapi-token",
         params: { object: 'whatsapp_business_account', entry: [{ changes: [{ value: { metadata: { phone_number_id: '1' } } }] }] }, as: :json

    expect(Webhooks::WhatsappEventsJob).to have_received(:perform_later) do |args|
      expect(args).not_to have_key('object')
      expect(args['phone_number']).to eq(channel.phone_number)
    end
  end

  it 'answers 401 to a wrong token, an unknown channel and an inbox of another provider alike' do
    baileys = create(:channel_whatsapp, provider: 'baileys', sync_templates: false, validate_provider_config: false)

    post "/webhooks/whatsapp/zapi/#{channel.id}/wrong", params: { type: 'ReceivedCallback' }, as: :json
    expect(response).to have_http_status(:unauthorized)

    post '/webhooks/whatsapp/zapi/0/zapi-token', params: { type: 'ReceivedCallback' }, as: :json
    expect(response).to have_http_status(:unauthorized)

    post "/webhooks/whatsapp/zapi/#{baileys.id}/#{baileys.provider_config['webhook_verify_token']}", params: { type: 'ReceivedCallback' }, as: :json
    expect(response).to have_http_status(:unauthorized)

    expect(Webhooks::WhatsappEventsJob).not_to have_received(:perform_later)
  end

  it 'answers 401 to an inbox that has no token yet' do
    channel.update_column(:provider_config, channel.provider_config.except('webhook_verify_token')) # rubocop:disable Rails/SkipsModelValidations

    post "/webhooks/whatsapp/zapi/#{channel.id}/anything", params: { type: 'ReceivedCallback' }, as: :json

    expect(response).to have_http_status(:unauthorized)
    expect(Webhooks::WhatsappEventsJob).not_to have_received(:perform_later)
  end

  context 'when a rotation replaced the token' do
    before do
      channel.update_column(:provider_config, channel.provider_config.merge('previous_webhook_verify_token' => 'leaked-token')) # rubocop:disable Rails/SkipsModelValidations
    end

    # Until Z-API is known to use the new URL, the old one is all that keeps the inbox receiving.
    it 'still takes the replaced token' do
      post "/webhooks/whatsapp/zapi/#{channel.id}/leaked-token", params: { type: 'ReceivedCallback' }, as: :json

      expect(response).to have_http_status(:ok)
      expect(channel.reload.provider_config['previous_webhook_verify_token']).to eq('leaked-token')
    end

    it 'closes the replaced token once a delivery arrives with the new one' do
      post "/webhooks/whatsapp/zapi/#{channel.id}/zapi-token", params: { type: 'ReceivedCallback' }, as: :json
      post "/webhooks/whatsapp/zapi/#{channel.id}/leaked-token", params: { type: 'ReceivedCallback' }, as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(channel.reload.provider_config).not_to have_key('previous_webhook_verify_token')
      expect(Webhooks::WhatsappEventsJob).to have_received(:perform_later).once
    end
  end
end
