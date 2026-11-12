require 'rails_helper'

RSpec.describe 'Super Admin User diagnostics incoming calls', type: :request do
  let(:super_admin) { create(:super_admin) }
  let(:user) { create(:user, email: 'agent@example.com') }

  before do
    sign_in(super_admin, scope: :super_admin)
    user.update!(tokens: { 'client-1' => { 'token' => 'token', 'expiry' => 1.day.from_now.to_i } })
  end

  it 'shows on the mobile tab whether calls ring the user on their phone' do
    account = create(:account, name: 'Acme')
    account.enable_features!('channel_voice', 'mobile_voice_push')
    create(:account_user, user: user, account: account)

    get '/super_admin/user_diagnostics', params: { user_query: user.email, tab: 'mobile' }

    expect(response.body).to include('Incoming calls')
    expect(response.body).to include('Needs APNS_VOIP_KEY, APNS_VOIP_KEY_ID and APNS_VOIP_TEAM_ID')
    expect(response.body).to include('No, no voice inboxes')
  end

  it 'shows the account a call cannot reach as off rather than ringing with the app open' do
    account = create(:account, name: 'Acme')
    account.enable_features!('mobile_voice_push')
    account.disable_features!('channel_voice')
    create(:account_user, user: user, account: account)

    get '/super_admin/user_diagnostics', params: { user_query: user.email, tab: 'mobile' }

    expect(response.body).to include('No, Voice Channel is off')
    expect(response.body).not_to include('Only with the app open')
  end
end
