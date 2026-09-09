require 'rails_helper'

RSpec.describe Channels::Whatsapp::HealthSyncJob do
  let(:whatsapp_channel) do
    create(
      :channel_whatsapp,
      provider: 'whatsapp_cloud',
      sync_templates: false,
      validate_provider_config: false
    )
  end
  let(:health_service) { instance_double(Whatsapp::HealthService, sync_health_status!: true) }

  it 'enqueues on the low priority queue' do
    expect { described_class.perform_later(whatsapp_channel) }
      .to have_enqueued_job(described_class).with(whatsapp_channel).on_queue('low')
  end

  it 'synchronizes the channel health status' do
    allow(Whatsapp::HealthService).to receive(:new).with(whatsapp_channel).and_return(health_service)

    described_class.perform_now(whatsapp_channel)

    expect(health_service).to have_received(:sync_health_status!)
  end

  it 'does not retry recorded API failures' do
    error = Whatsapp::HealthService::ApiError.new(message: 'Request failed', http_status: 400)
    allow(Whatsapp::HealthService).to receive(:new).with(whatsapp_channel).and_return(health_service)
    allow(health_service).to receive(:sync_health_status!).and_raise(error)

    expect { described_class.perform_now(whatsapp_channel) }.not_to raise_error
  end

  it 'does not retry recorded configuration failures' do
    allow(Whatsapp::HealthService).to receive(:new).with(whatsapp_channel).and_return(health_service)
    allow(health_service).to receive(:sync_health_status!).and_raise(ArgumentError, 'API key is missing')

    expect { described_class.perform_now(whatsapp_channel) }.not_to raise_error
  end

  it 'retries unexpected failures' do
    allow(Whatsapp::HealthService).to receive(:new).with(whatsapp_channel).and_return(health_service)
    allow(health_service).to receive(:sync_health_status!).and_raise(StandardError, 'Database unavailable')

    expect { described_class.perform_now(whatsapp_channel) }.to raise_error(StandardError, 'Database unavailable')
  end
end
