require 'rails_helper'

RSpec.describe Voice::RelayDeviceSync do
  let(:user) { create(:user) }
  let(:devices_url) { "#{ChatwootHub.base_url}/voice_relay/devices" }

  around { |example| with_modified_env(CHATWOOT_VOICE_RELAY_SECRET: 'relay-secret') { example.run } }

  before do
    allow(GlobalConfigService).to receive(:load) { |_key, default| default }
    stub_request(:put, devices_url)
    stub_request(:delete, devices_url)
  end

  def subscribe(type, token, platform: nil)
    attributes = { 'push_token' => token, 'device_id' => SecureRandom.hex(4) }
    attributes['devicePlatform'] = platform if platform
    user.notification_subscriptions.create!(subscription_type: type, identifier: SecureRandom.hex(4), subscription_attributes: attributes)
  end

  it 'registers a token a subscription holds and removes one none does' do
    subscribe('apns_voip', 'apple-1')

    described_class.new(platform: 'apple', token: 'apple-1').perform
    described_class.new(platform: 'apple', token: 'apple-old').perform

    expect(a_request(:put, devices_url).with(body: { platform: 'apple', token: 'apple-1' }.to_json,
                                             headers: { 'Authorization' => 'Bearer relay-secret' })).to have_been_made
    expect(a_request(:delete, devices_url).with(body: { platform: 'apple', token: 'apple-old' }.to_json)).to have_been_made
  end

  it 'does nothing for a platform the installation sends to itself' do
    allow(GlobalConfigService).to receive(:load) { |key, default| key.start_with?('APNS_VOIP_KEY', 'APNS_VOIP_TEAM') ? 'set' : default }

    described_class.new(platform: 'apple', token: 'apple-1').perform

    expect(a_request(:any, devices_url)).not_to have_been_made
  end

  describe 'on subscription changes' do
    it 'queues a sync for a new token and for the token it replaced' do
      subscription = subscribe('fcm', 'android-1', platform: 'Android')
      subscription.update!(subscription_attributes: subscription.subscription_attributes.merge('push_token' => 'android-2'))

      expect(Voice::RelayDeviceSyncJob).to have_been_enqueued.with('android', 'android-1').twice
      expect(Voice::RelayDeviceSyncJob).to have_been_enqueued.with('android', 'android-2')
    end

    it 'queues a sync when the subscription is removed' do
      subscription = subscribe('apns_voip', 'apple-1')
      clear_enqueued_jobs
      subscription.destroy!

      expect(Voice::RelayDeviceSyncJob).to have_been_enqueued.with('apple', 'apple-1')
    end

    it 'leaves out iOS FCM tokens and installations without a relay secret' do
      subscribe('fcm', 'ios-fcm', platform: 'iOS')
      with_modified_env(CHATWOOT_VOICE_RELAY_SECRET: nil) { subscribe('apns_voip', 'apple-1') }

      expect(Voice::RelayDeviceSyncJob).not_to have_been_enqueued
    end
  end

  it 'registers every phone daily, a batch at a time' do
    subscribe('apns_voip', 'apple-1')
    subscribe('fcm', 'android-1', platform: 'Android')
    stub_const('Voice::RelayDeviceReconcileJob::BATCH_SIZE', 1)

    Voice::RelayDeviceReconcileJob.perform_now

    expect(a_request(:put, devices_url)).to have_been_made.once
    expect(Voice::RelayDeviceReconcileJob).to have_been_enqueued.with(NotificationSubscription.first.id)
  end

  it 'leaves a phone another installation registered, and keeps going' do
    subscribe('apns_voip', 'apple-taken')
    subscribe('apns_voip', 'apple-1')
    stub_request(:put, devices_url).with(body: hash_including(token: 'apple-taken')).to_return(status: 409)

    expect { Voice::RelayDeviceReconcileJob.perform_now }.not_to raise_error
    expect(a_request(:put, devices_url).with(body: hash_including(token: 'apple-1'))).to have_been_made
  end
end
