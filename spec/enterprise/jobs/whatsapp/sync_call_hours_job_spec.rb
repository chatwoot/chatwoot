require 'rails_helper'

RSpec.describe Whatsapp::SyncCallHoursJob do
  let(:channel) do
    create(:channel_whatsapp, provider: 'whatsapp_cloud', validate_provider_config: false, sync_templates: false)
  end
  let(:lock_key) { format(Redis::Alfred::WHATSAPP_CALL_HOURS_SYNC_MUTEX, channel_id: channel.id) }
  let(:sync_service) { instance_double(Whatsapp::CallHoursSyncService, perform: true) }

  before { allow(Whatsapp::CallHoursSyncService).to receive(:new).with(channel: channel).and_return(sync_service) }

  it 'syncs a pending channel' do
    channel.update!(call_hours_sync_status: 'pending')

    described_class.perform_now(channel)

    expect(sync_service).to have_received(:perform)
  end

  it 'skips a channel another job already synced' do
    channel.update!(call_hours_sync_status: 'synced')

    described_class.perform_now(channel)

    expect(sync_service).not_to have_received(:perform)
  end

  it 'waits for a sync already running for the number' do
    channel.update!(call_hours_sync_status: 'pending')
    Redis::LockManager.new.lock(lock_key, 1.minute)

    expect { described_class.perform_now(channel) }.to have_enqueued_job(described_class)
    expect(sync_service).not_to have_received(:perform)
  ensure
    Redis::LockManager.new.unlock(lock_key)
  end
end
