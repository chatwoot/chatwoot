require 'rails_helper'

RSpec.describe Voice::RingReadiness do
  let(:account) { create(:account) }
  let(:user) { create(:user) }
  let!(:account_user) { create(:account_user, account: account, user: user) }
  let(:config) { { 'APNS_VOIP_KEY' => 'p8', 'APNS_VOIP_KEY_ID' => 'KEY1', 'APNS_VOIP_TEAM_ID' => 'TEAM1' } }
  let(:readiness) { described_class.new(user: user) }

  before do
    allow(GlobalConfigService).to receive(:load) { |key, default| config.fetch(key, default) }
    account.enable_features!('channel_voice', 'mobile_voice_push')
    user.notification_subscriptions.create!(subscription_type: 'apns_voip', identifier: 'voip:device-1',
                                            subscription_attributes: { 'push_token' => 'voip-1', 'device_id' => 'device-1' })
  end

  it 'rings an online agent with an iPhone on an account with both features' do
    expect(readiness.apple).to have_attributes(configured: true, devices: 1)
    expect(readiness.rings?(readiness.memberships.first)).to be(true)
  end

  it 'does not ring an agent who is not online' do
    account_user.update!(availability: :busy)

    expect(readiness.rings?(readiness.memberships.first)).to be(false)
  end

  it 'does not ring on an account without the mobile push feature' do
    account.disable_features!('mobile_voice_push')

    expect(readiness.rings?(readiness.memberships.first)).to be(false)
  end

  it 'does not ring when the installation cannot push to any registered device' do
    config.delete('APNS_VOIP_KEY')

    expect(readiness.apple.configured).to be(false)
    expect(readiness.rings?(readiness.memberships.first)).to be(false)
  end

  it 'counts only Android phones among FCM devices' do
    config.merge!('FIREBASE_PROJECT_ID' => 'project', 'FIREBASE_CREDENTIALS' => '{}')
    user.notification_subscriptions.create!(subscription_type: 'fcm', identifier: 'android-1',
                                            subscription_attributes: { 'push_token' => 'a1', 'devicePlatform' => 'Android' })
    user.notification_subscriptions.create!(subscription_type: 'fcm', identifier: 'ios-1',
                                            subscription_attributes: { 'push_token' => 'i1', 'devicePlatform' => 'iOS' })

    expect(readiness.android).to have_attributes(configured: true, devices: 1)
  end
end
