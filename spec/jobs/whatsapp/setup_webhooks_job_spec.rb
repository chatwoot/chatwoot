require 'rails_helper'

RSpec.describe Whatsapp::SetupWebhooksJob do
  subject(:job) { described_class.new }

  let(:account) { create(:account) }
  let(:channel) do
    create(:channel_whatsapp, account: account, phone_number: '+1234567890',
                              validate_provider_config: false, sync_templates: false)
  end
  let(:health_service) { instance_double(Whatsapp::HealthService) }
  let(:healthy_status) do
    { platform_type: 'CLOUD_API', throughput: { 'level' => 'STANDARD' }, messaging_limit_tier: 'TIER_1000' }
  end

  before do
    allow(channel).to receive(:setup_webhooks)
    allow(Whatsapp::HealthService).to receive(:new).with(channel).and_return(health_service)
    allow(health_service).to receive(:fetch_health_status).and_return(healthy_status)
  end

  it 'sets up the channel webhooks' do
    expect(channel).to receive(:setup_webhooks)
    job.perform(channel)
  end

  it 'checks health status after webhook setup' do
    expect(health_service).to receive(:fetch_health_status)
    job.perform(channel)
  end

  context 'when the channel is healthy' do
    it 'does not prompt reauthorization' do
      expect(channel).not_to receive(:prompt_reauthorization!)
      job.perform(channel)
    end
  end

  context 'when the channel is in a pending state' do
    it 'prompts reauthorization for a NOT_APPLICABLE platform type' do
      allow(health_service).to receive(:fetch_health_status)
        .and_return(healthy_status.merge(platform_type: 'NOT_APPLICABLE'))

      expect(channel).to receive(:prompt_reauthorization!)
      job.perform(channel)
    end

    it 'prompts reauthorization when throughput level is NOT_APPLICABLE' do
      allow(health_service).to receive(:fetch_health_status)
        .and_return(healthy_status.merge(throughput: { 'level' => 'NOT_APPLICABLE' }))

      expect(channel).to receive(:prompt_reauthorization!)
      job.perform(channel)
    end
  end

  context 'when run_health_check is false' do
    it 'skips the health check' do
      expect(Whatsapp::HealthService).not_to receive(:new)
      job.perform(channel, run_health_check: false)
    end
  end

  context 'when the health check raises' do
    it 'rescues the error without raising' do
      allow(health_service).to receive(:fetch_health_status).and_raise('Health error')

      expect { job.perform(channel) }.not_to raise_error
    end
  end
end
