require 'rails_helper'

RSpec.describe Migration::ZapiWebhookUrlJob do
  let(:zapi_config) { { 'instance_id' => 'instance', 'token' => 'zapi-api-token', 'client_token' => 'client' } }
  let(:legacy) { create(:channel_whatsapp, provider: 'zapi', provider_config: zapi_config, validate_provider_config: false, sync_templates: false) }
  let(:moved) do
    create(:channel_whatsapp, provider: 'zapi', validate_provider_config: false, sync_templates: false).tap do |channel|
      channel.provider_config = zapi_config.merge('webhook_verify_token' => 'already', 'webhook_url_confirmed_for' => 'instance')
      channel.save!(validate: false)
    end
  end
  let(:instance_path) { "#{Whatsapp::Providers::WhatsappZapiService::API_BASE_PATH}/instances/instance/token/zapi-api-token" }
  let(:webhooks_url) { "#{instance_path}/update-every-webhooks" }
  let(:legacy_url) { "https://chat.example.com/webhooks/whatsapp/#{legacy.phone_number}" }
  let(:instance_webhooks) do
    { 'receivedCallbackUrl' => legacy_url, 'deliveryCallbackUrl' => legacy_url, 'messageStatusCallbackUrl' => legacy_url,
      'connectedCallbackUrl' => legacy_url, 'disconnectedCallbackUrl' => legacy_url, 'presenceChatCallbackUrl' => legacy_url }
  end

  around { |example| with_modified_env(FRONTEND_URL: 'https://chat.example.com') { example.run } }

  before do
    stub_request(:get, "#{instance_path}/me").to_return do
      { status: 200, body: instance_webhooks.to_json, headers: { 'Content-Type' => 'application/json' } }
    end
  end

  it 'moves an inbox still on the old URL and leaves a moved one alone' do
    legacy
    moved
    stub_request(:put, webhooks_url).to_return(status: 200)

    expect(described_class.perform_now).to eq(moved: 1, skipped: 0, failed: 0)
    expect(legacy.reload.provider_config).to include('webhook_url_confirmed_for' => 'instance')
    expect(moved.reload.provider_config['webhook_verify_token']).to eq('already')
    expect(a_request(:put, webhooks_url)).to have_been_made.once
  end

  # update-every-webhooks overwrites every event's URL; one someone sent elsewhere is not the job's to take.
  it 'leaves alone an instance with a webhook pointing somewhere else' do
    legacy
    instance_webhooks['presenceChatCallbackUrl'] = 'https://n8n.example.com/presence'
    allow(Rails.logger).to receive(:warn)

    expect(described_class.perform_now).to eq(moved: 0, skipped: 1, failed: 0)
    expect(a_request(:put, webhooks_url)).not_to have_been_made
    expect(legacy.reload.provider_config).not_to have_key('webhook_verify_token')
    expect(Rails.logger).to have_received(:warn).with(/left alone, webhooks point elsewhere channel_id=#{legacy.id}/)
  end

  it 'leaves alone an instance set up by another installation' do
    legacy
    instance_webhooks.transform_values! { 'https://staging.example.com/webhooks/whatsapp/x' }
    allow(Rails.logger).to receive(:warn)

    expect(described_class.perform_now).to eq(moved: 0, skipped: 1, failed: 0)
  end

  it 'takes the number with its + escaped as the same URL' do
    legacy
    instance_webhooks.transform_values! { legacy_url.sub('+', '%2B') }
    stub_request(:put, webhooks_url).to_return(status: 200)

    expect(described_class.perform_now).to eq(moved: 1, skipped: 0, failed: 0)
  end

  # The check covered one instance; an inbox pointed at another meanwhile is not overwritten blind.
  it 'does not register an instance it did not check' do
    legacy
    stub_request(:get, "#{instance_path}/me").to_return do
      Channel::Whatsapp.find(legacy.id).tap do |other|
        other.provider_config = other.provider_config.merge('instance_id' => 'replacement')
        other.save!(validate: false)
      end
      { status: 200, body: instance_webhooks.to_json, headers: { 'Content-Type' => 'application/json' } }
    end
    stub_request(:put, /update-every-webhooks/).to_return(status: 200)
    allow(Rails.logger).to receive(:warn)

    expect(described_class.perform_now).to eq(moved: 0, skipped: 0, failed: 1)
    expect(a_request(:put, /update-every-webhooks/)).not_to have_been_made
    expect(legacy.reload.provider_config).not_to have_key('webhook_url_confirmed_for')
  end

  # An inbox it cannot reach stays on the old URL, which keeps taking its events.
  it 'leaves an inbox it cannot reach on the old URL and carries on' do
    legacy
    stub_request(:put, webhooks_url).to_return(status: 500, body: 'down')
    allow(Rails.logger).to receive(:warn)

    expect(described_class.perform_now).to eq(moved: 0, skipped: 0, failed: 1)
    expect(legacy.reload.provider_config).not_to have_key('webhook_url_confirmed_for')
    expect(Rails.logger).to have_received(:warn).with(/still on the old URL channel_id=#{legacy.id}/)
  end
end
