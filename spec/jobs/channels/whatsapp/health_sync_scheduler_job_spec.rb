require 'rails_helper'

RSpec.describe Channels::Whatsapp::HealthSyncSchedulerJob do
  it 'enqueues on the low priority queue' do
    expect { described_class.perform_later }.to have_enqueued_job(described_class).on_queue('low')
  end

  it 'schedules stale and unchecked active Cloud API channels' do
    unchecked = create(
      :channel_whatsapp,
      provider: 'whatsapp_cloud',
      phone_number_health_checked_at: nil,
      sync_templates: false,
      validate_provider_config: false
    )
    stale = create(
      :channel_whatsapp,
      provider: 'whatsapp_cloud',
      phone_number_health_checked_at: 7.hours.ago,
      sync_templates: false,
      validate_provider_config: false
    )
    recent = create(
      :channel_whatsapp,
      provider: 'whatsapp_cloud',
      phone_number_health_checked_at: 1.hour.ago,
      sync_templates: false,
      validate_provider_config: false
    )
    non_cloud = create(
      :channel_whatsapp,
      provider: 'default',
      phone_number_health_checked_at: 7.hours.ago,
      sync_templates: false,
      validate_provider_config: false
    )
    suspended = create(
      :channel_whatsapp,
      account: create(:account, status: :suspended),
      provider: 'whatsapp_cloud',
      phone_number_health_checked_at: nil,
      sync_templates: false,
      validate_provider_config: false
    )

    described_class.perform_now

    expect(Channels::Whatsapp::HealthSyncJob).to have_been_enqueued.with(unchecked).on_queue('low')
    expect(Channels::Whatsapp::HealthSyncJob).to have_been_enqueued.with(stale).on_queue('low')
    expect(Channels::Whatsapp::HealthSyncJob).not_to have_been_enqueued.with(recent).on_queue('low')
    expect(Channels::Whatsapp::HealthSyncJob).not_to have_been_enqueued.with(non_cloud).on_queue('low')
    expect(Channels::Whatsapp::HealthSyncJob).not_to have_been_enqueued.with(suspended).on_queue('low')
  end

  it 'schedules unchecked and oldest channels first when the batch is limited' do
    stub_const('Limits::BULK_EXTERNAL_HTTP_CALLS_LIMIT', 2)
    unchecked = create(
      :channel_whatsapp,
      provider: 'whatsapp_cloud',
      phone_number_health_checked_at: nil,
      sync_templates: false,
      validate_provider_config: false
    )
    older = create(
      :channel_whatsapp,
      provider: 'whatsapp_cloud',
      phone_number_health_checked_at: 9.hours.ago,
      sync_templates: false,
      validate_provider_config: false
    )
    newer = create(
      :channel_whatsapp,
      provider: 'whatsapp_cloud',
      phone_number_health_checked_at: 7.hours.ago,
      sync_templates: false,
      validate_provider_config: false
    )

    described_class.perform_now

    expect(Channels::Whatsapp::HealthSyncJob).to have_been_enqueued.with(unchecked).on_queue('low')
    expect(Channels::Whatsapp::HealthSyncJob).to have_been_enqueued.with(older).on_queue('low')
    expect(Channels::Whatsapp::HealthSyncJob).not_to have_been_enqueued.with(newer).on_queue('low')
  end
end
