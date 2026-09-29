require 'rails_helper'

RSpec.describe 'Unknown sign-in notification', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, password: 'Password1!', account: account) }

  def sign_in!(headers: {})
    post new_user_session_url, params: { email: user.email, password: 'Password1!' }, headers: headers, as: :json
  end

  # A session row only survives sign-in if its client_id has a live token (User#sync_user_sessions).
  def seed_session(client_id, last_activity_at:)
    user.update!(tokens: (user.tokens || {}).merge(client_id => { 'token' => 'x', 'expiry' => 1.month.from_now.to_i }))
    user.user_sessions.create!(client_id: client_id, ip_address: '127.0.0.1', last_activity_at: last_activity_at)
  end

  before do
    create(:installation_config, name: 'UNKNOWN_SIGNIN_NOTIFICATION_ENABLED', value: true)
    GlobalConfig.clear_cache
    user.update!(sign_in_count: 5)
  end

  it 'increments sign_in_count through devise trackable' do
    expect { sign_in! }.to change { user.reload.sign_in_count }.by(1)
    expect(response).to have_http_status(:success)
  end

  it 'enqueues the alert for a sign-in with no recognition signals' do
    expect { sign_in! }.to have_enqueued_job(Enterprise::UnknownSignInNotificationJob).with(user.email, anything)
  end

  it 'does not enqueue on the first-ever sign-in' do
    user.update!(sign_in_count: 0)
    expect { sign_in! }.not_to have_enqueued_job(Enterprise::UnknownSignInNotificationJob)
  end

  it 'recognizes the browser on the next sign-in through the known-sign-in cookie' do
    sign_in!
    user.reload.user_sessions.delete_all
    expect { sign_in! }.not_to have_enqueued_job(Enterprise::UnknownSignInNotificationJob)
  end

  it 'does not enqueue when an active session exists from the same IP' do
    seed_session('known-client', last_activity_at: 1.hour.ago)
    expect { sign_in! }.not_to have_enqueued_job(Enterprise::UnknownSignInNotificationJob)
  end

  it 'enqueues when the only session from this IP is stale' do
    seed_session('stale-client', last_activity_at: 20.days.ago)
    expect { sign_in! }.to have_enqueued_job(Enterprise::UnknownSignInNotificationJob)
  end

  it 'stops recognizing the browser once the cookie window has lapsed' do
    sign_in!
    user.reload.user_sessions.delete_all
    travel_to(15.days.from_now) do
      expect { sign_in! }.to have_enqueued_job(Enterprise::UnknownSignInNotificationJob)
    end
  end

  it 'stops recognizing the cookie after device_trust_version is bumped' do
    sign_in!
    user.reload.user_sessions.delete_all
    user.update!(device_trust_version: user.device_trust_version + 1)
    expect { sign_in! }.to have_enqueued_job(Enterprise::UnknownSignInNotificationJob).once
  end

  it 'does not enqueue for an SSO sign-in' do
    token = user.generate_sso_auth_token
    expect do
      post new_user_session_url, params: { email: user.email, sso_auth_token: token }, as: :json
    end.not_to have_enqueued_job(Enterprise::UnknownSignInNotificationJob)
  end

  it 'does not enqueue for a failed sign-in' do
    expect do
      post new_user_session_url, params: { email: user.email, password: 'wrong' }, as: :json
    end.not_to have_enqueued_job(Enterprise::UnknownSignInNotificationJob)
  end

  it 'passes resolved mobile device labels to the job' do
    sign_in!(headers: { 'X-Chatwoot-Client-Name' => 'Chatwoot Mobile', 'X-Chatwoot-Platform' => 'android',
                        'X-Chatwoot-Device-Model' => 'Pixel 9' })
    expect(Enterprise::UnknownSignInNotificationJob).to have_been_enqueued.with(
      user.email, hash_including(browser_name: 'Chatwoot Mobile', platform_name: 'Android')
    )
  end

  context 'when the sign-in completed through device verification' do
    let(:emailed_codes) { [] }
    let(:mailer_message) { instance_double(ActionMailer::MessageDelivery, deliver_later: true) }

    before do
      allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(true)
      create(:installation_config, name: 'DEVICE_VERIFICATION_ENABLED', value: true)
      GlobalConfig.clear_cache
      allow(Enterprise::DeviceVerificationMailer).to receive(:verification_code) do |_user, encrypted_code, _meta|
        emailed_codes << DeviceVerification.decrypt_code(encrypted_code)
        mailer_message
      end
      allow(Enterprise::DeviceVerificationMailer).to receive(:new_device).and_return(mailer_message)
    end

    it 'does not also send the unknown sign-in alert' do
      sign_in!
      mfa_token = response.parsed_body['mfa_token']
      expect do
        post new_user_session_url, params: { mfa_token: mfa_token, otp_code: emailed_codes.last }, as: :json
      end.not_to have_enqueued_job(Enterprise::UnknownSignInNotificationJob)
      expect(response).to have_http_status(:success)
      expect(Enterprise::DeviceVerificationMailer).to have_received(:new_device)
    end
  end

  context 'when the feature is disabled' do
    before do
      InstallationConfig.find_by(name: 'UNKNOWN_SIGNIN_NOTIFICATION_ENABLED').update!(value: false)
      GlobalConfig.clear_cache
    end

    it 'does not enqueue but still recognizes the browser once re-enabled' do
      expect { sign_in! }.not_to have_enqueued_job(Enterprise::UnknownSignInNotificationJob)

      InstallationConfig.find_by(name: 'UNKNOWN_SIGNIN_NOTIFICATION_ENABLED').update!(value: true)
      GlobalConfig.clear_cache
      user.user_sessions.delete_all
      expect { sign_in! }.not_to have_enqueued_job(Enterprise::UnknownSignInNotificationJob)
    end
  end
end
