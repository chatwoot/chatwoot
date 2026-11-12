require 'rails_helper'

RSpec.describe Channels::Whatsapp::EmbeddedSignupSetupJob do
  let(:channel) do
    create(:channel_whatsapp, provider: 'whatsapp_cloud', sync_templates: false, validate_provider_config: false)
  end
  let(:health_service) { instance_double(Whatsapp::HealthService) }
  let(:webhook_setup) { instance_double(Whatsapp::WebhookSetupService, perform: true, registration_error: nil) }
  let(:healthy) { { platform_type: 'CLOUD_API', throughput: { 'level' => 'STANDARD' } } }

  before do
    allow(Whatsapp::WebhookSetupService).to receive(:new).with(channel, is_coexistence: anything).and_return(webhook_setup)
    allow(Whatsapp::HealthService).to receive(:new).with(channel).and_return(health_service)
    allow(health_service).to receive(:fetch_health_status).and_return(healthy)
  end

  it 'runs on the high queue' do
    expect { described_class.perform_later(channel, is_coexistence: false, check_health: true) }
      .to have_enqueued_job(described_class).on_queue('high')
  end

  it 'sets up webhooks with the coexistence signal' do
    described_class.perform_now(channel, is_coexistence: true, check_health: false)

    expect(Whatsapp::WebhookSetupService).to have_received(:new).with(channel, is_coexistence: true)
    expect(webhook_setup).to have_received(:perform)
  end

  it 'does not check health when asked not to' do
    described_class.perform_now(channel, is_coexistence: false, check_health: false)

    expect(Whatsapp::HealthService).not_to have_received(:new)
  end

  it 'leaves a healthy channel alone' do
    described_class.perform_now(channel, is_coexistence: false, check_health: true)

    expect(channel.reauthorization_required?).to be false
  end

  it 'prompts reauthorization when Meta still reports the number as pending' do
    allow(health_service).to receive(:fetch_health_status).and_return(healthy.merge(platform_type: 'NOT_APPLICABLE'))

    described_class.perform_now(channel, is_coexistence: false, check_health: true)

    expect(channel.reauthorization_required?).to be true
  end

  it 'prompts reauthorization when the throughput level is NOT_APPLICABLE' do
    allow(health_service).to receive(:fetch_health_status).and_return(healthy.merge(throughput: { 'level' => 'NOT_APPLICABLE' }))

    described_class.perform_now(channel, is_coexistence: false, check_health: true)

    expect(channel.reauthorization_required?).to be true
  end

  it 'prompts reauthorization when webhook setup fails' do
    allow(webhook_setup).to receive(:perform).and_raise('Webhook setup error')

    described_class.perform_now(channel, is_coexistence: false, check_health: false)

    expect(channel.reauthorization_required?).to be true
  end

  # A reconnect has already cleared the reconnect banner, and skips the health check.
  it 'prompts reauthorization when registration fails even though the webhook was subscribed' do
    allow(webhook_setup).to receive(:registration_error).and_return(StandardError.new('(#133005) Two step verification PIN mismatch'))

    described_class.perform_now(channel, is_coexistence: false, check_health: false)

    expect(channel.reauthorization_required?).to be true
  end

  it 'skips the health check after a failed setup' do
    allow(webhook_setup).to receive(:perform).and_raise('Webhook setup error')

    described_class.perform_now(channel, is_coexistence: false, check_health: true)

    expect(Whatsapp::HealthService).not_to have_received(:new)
  end

  it 'does not raise when the health check itself fails' do
    allow(health_service).to receive(:fetch_health_status).and_raise('Graph error')

    expect { described_class.perform_now(channel, is_coexistence: false, check_health: true) }.not_to raise_error
  end
end
