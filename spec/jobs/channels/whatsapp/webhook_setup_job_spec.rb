require 'rails_helper'

RSpec.describe Channels::Whatsapp::WebhookSetupJob do
  let(:channel) do
    create(:channel_whatsapp, validate_provider_config: false, sync_templates: false)
  end

  it 'runs webhook setup' do
    allow(channel).to receive(:setup_webhooks)

    described_class.perform_now(channel)

    expect(channel).to have_received(:setup_webhooks)
  end

  it 'runs the provisioning health check when requested' do
    allow(channel).to receive(:setup_webhooks)
    allow(channel).to receive(:check_provisioning_health)

    described_class.perform_now(channel, run_health_check: true)

    expect(channel).to have_received(:check_provisioning_health)
  end

  it 'skips the provisioning health check by default' do
    allow(channel).to receive(:setup_webhooks)
    allow(channel).to receive(:check_provisioning_health)

    described_class.perform_now(channel)

    expect(channel).not_to have_received(:check_provisioning_health)
  end

  context 'when webhook setup keeps failing' do
    before do
      setup_service = instance_double(Whatsapp::WebhookSetupService)
      allow(Whatsapp::WebhookSetupService).to receive(:new).and_return(setup_service)
      allow(setup_service).to receive(:perform).and_raise(StandardError, 'meta down')
    end

    it 'retries and marks the channel for reauthorization once retries are exhausted' do
      expect(channel.reauthorization_required?).to be false

      perform_enqueued_jobs { described_class.perform_later(channel) }

      expect(channel.reauthorization_required?).to be true
    end
  end
end
