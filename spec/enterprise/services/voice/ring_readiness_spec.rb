require 'rails_helper'

RSpec.describe Voice::RingReadiness do
  let(:account) { create(:account) }
  let(:user) { create(:user) }
  let!(:account_user) { create(:account_user, account: account, user: user) }
  let(:config) { { 'APNS_VOIP_KEY' => 'p8', 'APNS_VOIP_KEY_ID' => 'KEY1', 'APNS_VOIP_TEAM_ID' => 'TEAM1' } }
  let(:readiness) { described_class.new(user: user) }
  let(:voice_inbox) { create(:channel_twilio_sms, :with_voice, account: account).inbox }

  before do
    allow(Twilio::VoiceWebhookSetupService).to receive(:new)
      .and_return(instance_double(Twilio::VoiceWebhookSetupService, perform: "AP#{SecureRandom.hex(16)}"))
    allow(GlobalConfigService).to receive(:load) { |key, default| config.fetch(key, default) }
    account.enable_features!('channel_voice', 'mobile_voice_push')
    create(:inbox_member, inbox: voice_inbox, user: user)
    user.notification_subscriptions.create!(subscription_type: 'apns_voip', identifier: 'voip:device-1',
                                            subscription_attributes: { 'push_token' => 'voip-1', 'device_id' => 'device-1' })
  end

  it 'rings an online agent of a voice inbox with an iPhone on an account with both features' do
    expect(readiness.apple).to have_attributes(configured: true, devices: 1)
    expect(readiness.memberships.first.voice_inboxes).to eq(1)
    expect(readiness.rings?(readiness.memberships.first)).to be(true)
    expect(readiness.blocker(readiness.memberships.first)).to be_nil
    expect(readiness.rings_assigned_only?(readiness.memberships.first)).to be(false)
  end

  it 'does not ring an agent who is not online' do
    account_user.update!(availability: :busy)

    expect(readiness.rings?(readiness.memberships.first)).to be(false)
    expect(readiness.blocker(readiness.memberships.first)).to eq('not_online')
  end

  it 'does not ring an agent outside every voice inbox' do
    InboxMember.where(user: user).destroy_all

    expect(readiness.memberships.first.voice_inboxes).to eq(0)
    expect(readiness.rings?(readiness.memberships.first)).to be(false)
    expect(readiness.blocker(readiness.memberships.first)).to eq('no_inboxes')
  end

  it 'rings an agent whose role opens only assigned conversations for the calls assigned to them' do
    account_user.update!(custom_role: create(:custom_role, account: account, permissions: ['conversation_participating_manage']))

    expect(readiness.memberships.first).to have_attributes(voice_inboxes: 1, assigned_only_inboxes: 1)
    expect(readiness.rings?(readiness.memberships.first)).to be(true)
    expect(readiness.rings_assigned_only?(readiness.memberships.first)).to be(true)
  end

  it 'does not count a voice inbox whose calls the role of the agent cannot open' do
    account_user.update!(custom_role: create(:custom_role, account: account, permissions: ['report_manage']))

    expect(readiness.memberships.first.voice_inboxes).to eq(0)
    expect(readiness.rings?(readiness.memberships.first)).to be(false)
  end

  it 'does not ring on an account without the mobile push feature' do
    account.disable_features!('mobile_voice_push')

    expect(readiness.rings?(readiness.memberships.first)).to be(false)
    expect(readiness.blocker(readiness.memberships.first)).to eq('ringing_off')
  end

  it 'reports Voice Channel before the other reasons on an account without it' do
    account.disable_features!('channel_voice')
    user.notification_subscriptions.destroy_all

    expect(readiness.blocker(readiness.memberships.first)).to eq('voice_off')
  end

  it 'does not ring an agent without a phone registered for calls' do
    user.notification_subscriptions.destroy_all

    expect(readiness.rings?(readiness.memberships.first)).to be(false)
    expect(readiness.blocker(readiness.memberships.first)).to eq('no_device')
  end

  it 'does not ring when the installation cannot push to any registered device' do
    config.delete('APNS_VOIP_KEY')

    expect(readiness.apple).to have_attributes(configured: false, problem: 'credentials')
    expect(readiness.rings?(readiness.memberships.first)).to be(false)
    expect(readiness.blocker(readiness.memberships.first)).to eq('push_unavailable')
  end

  it 'does not ring an Android phone while the APNs environment would stop the ring' do
    config.merge!('APNS_VOIP_ENVIRONMENT' => 'prod', 'FIREBASE_PROJECT_ID' => 'project', 'FIREBASE_CREDENTIALS' => '{}')
    user.notification_subscriptions.where(subscription_type: 'apns_voip').destroy_all
    user.notification_subscriptions.create!(subscription_type: 'fcm', identifier: 'android-1',
                                            subscription_attributes: { 'push_token' => 'a1', 'devicePlatform' => 'Android' })

    expect(readiness.android).to have_attributes(configured: true, devices: 1)
    expect(readiness.rings?(readiness.memberships.first)).to be(false)
  end

  it 'reports an APNs environment the push would reject' do
    config['APNS_VOIP_ENVIRONMENT'] = 'prod'

    expect(readiness.apple).to have_attributes(configured: false, problem: 'environment')
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
