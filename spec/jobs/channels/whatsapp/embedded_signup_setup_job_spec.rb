require 'rails_helper'

RSpec.describe Channels::Whatsapp::EmbeddedSignupSetupJob do
  let(:channel) do
    create(:channel_whatsapp, provider: 'whatsapp_cloud', sync_templates: false, validate_provider_config: false)
  end
  let(:health_service) { instance_double(Whatsapp::HealthService) }
  let(:healthy) { { platform_type: 'CLOUD_API', throughput: { 'level' => 'STANDARD' } } }

  before do
    allow(channel).to receive(:setup_webhooks)
    allow(Whatsapp::HealthService).to receive(:new).with(channel).and_return(health_service)
    allow(health_service).to receive(:fetch_health_status).and_return(healthy)
  end

  it 'runs on the high queue' do
    expect { described_class.perform_later(channel, is_coexistence: false, check_health: true) }
      .to have_enqueued_job(described_class).on_queue('high')
  end

  it 'sets up webhooks with the coexistence signal' do
    described_class.perform_now(channel, is_coexistence: true, check_health: false)

    expect(channel).to have_received(:setup_webhooks).with(is_coexistence: true)
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
    allow(channel).to receive(:setup_webhooks).and_call_original
    allow(channel).to receive(:perform_webhook_setup).and_raise('Webhook setup error')

    described_class.perform_now(channel, is_coexistence: false, check_health: false)

    expect(channel.reauthorization_required?).to be true
  end

  it 'does not raise when the health check itself fails' do
    allow(health_service).to receive(:fetch_health_status).and_raise('Graph error')

    expect { described_class.perform_now(channel, is_coexistence: false, check_health: true) }.not_to raise_error
  end
end
