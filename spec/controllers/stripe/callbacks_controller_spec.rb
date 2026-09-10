require 'rails_helper'

RSpec.describe 'Stripe OAuth callback', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:state) { 'b' * 64 }
  let(:token) do
    instance_double(OAuth2::AccessToken, token: 'stripe-access', refresh_token: 'stripe-refresh',
                                         params: { 'livemode' => false, 'stripe_user_id' => 'acct_test' })
  end
  let(:strategy) { instance_double(OAuth2::Strategy::AuthCode, get_token: token) }
  let(:client) { instance_double(OAuth2::Client, auth_code: strategy) }

  around do |example|
    with_modified_env FRONTEND_URL: 'http://www.example.com' do
      example.run
    end
  end

  before do
    allow(Integrations::Stripe::Oauth).to receive_messages(configured?: true, client: client, livemode?: false)
    allow(Integrations::Stripe::Oauth).to receive(:consume_state).with(state)
                                                                 .and_return('account_id' => account.id, 'user_id' => admin.id, 'livemode' => false)
  end

  it 'saves OAuth credentials in one integration hook and redirects back' do
    get '/stripe/callback', params: { state: state, code: 'authorization-code' }
    expect(response).to redirect_to(%r{/app/accounts/#{account.id}/settings/integrations/stripe\z})
    hook = account.hooks.find_by!(app_id: 'stripe')
    expect(hook.reference_id).to eq('acct_test')
    expect(hook.settings).to include('livemode' => false)
    expect(JSON.parse(hook.access_token)).to include('access_token' => 'stripe-access', 'refresh_token' => 'stripe-refresh')
  end

  it 'updates an existing hook instead of creating a duplicate' do
    hook = create(:integrations_hook, app_id: 'stripe', account: account, status: :disabled,
                                      settings: { 'connected_at' => 1.month.ago.iso8601 })
    previous_connection = hook.settings['connected_at']
    expect { get '/stripe/callback', params: { state: state, code: 'authorization-code' } }.not_to change(Integrations::Hook, :count)
    expect(hook.reload).to be_enabled
    expect(hook.reference_id).to eq('acct_test')
    expect(hook.settings['connected_at']).not_to eq(previous_connection)
    expect(Time.iso8601(hook.settings['connected_at'])).to be_within(2.seconds).of(Time.current)
  end

  it 'rejects invalid or already consumed state' do
    allow(Integrations::Stripe::Oauth).to receive(:consume_state).with(state).and_return(nil)
    expect(strategy).not_to receive(:get_token)
    get '/stripe/callback', params: { state: state, code: 'authorization-code' }
    expect(response).to have_http_status(:bad_request)
  end

  it 'rejects installation after the initiating user loses administrator access' do
    account.account_users.find_by!(user: admin).update!(role: :agent)
    expect(strategy).not_to receive(:get_token)
    get '/stripe/callback', params: { state: state, code: 'authorization-code' }
    expect(response).to have_http_status(:forbidden)
  end

  it 'does not exchange a code when consent is denied' do
    expect(strategy).not_to receive(:get_token)
    get '/stripe/callback', params: { state: state, error: 'access_denied' }
    expect(response).to redirect_to(/error=authorization_failed\z/)
    expect(account.hooks.where(app_id: 'stripe')).to be_empty
  end

  it 'rejects live-mode tokens for a sandbox authorization' do
    allow(token).to receive(:params).and_return('livemode' => true, 'stripe_user_id' => 'acct_live')
    get '/stripe/callback', params: { state: state, code: 'authorization-code' }
    expect(response).to redirect_to(/error=authorization_failed\z/)
    expect(account.hooks.where(app_id: 'stripe')).to be_empty
  end

  it 'stores a live connection after live authorization' do
    allow(Integrations::Stripe::Oauth).to receive(:livemode?).and_return(true)
    allow(Integrations::Stripe::Oauth).to receive(:consume_state).with(state)
                                                                 .and_return('account_id' => account.id, 'user_id' => admin.id, 'livemode' => true)
    allow(token).to receive(:params).and_return('livemode' => true, 'stripe_user_id' => 'acct_live')
    get '/stripe/callback', params: { state: state, code: 'authorization-code' }
    expect(response).to redirect_to(%r{/app/accounts/#{account.id}/settings/integrations/stripe\z})
    expect(account.hooks.find_by!(app_id: 'stripe').settings).to include('livemode' => true)
  end

  it 'rejects sandbox tokens for a live authorization' do
    allow(Integrations::Stripe::Oauth).to receive(:livemode?).and_return(true)
    allow(Integrations::Stripe::Oauth).to receive(:consume_state).with(state)
                                                                 .and_return('account_id' => account.id, 'user_id' => admin.id, 'livemode' => true)
    get '/stripe/callback', params: { state: state, code: 'authorization-code' }
    expect(response).to redirect_to(/error=authorization_failed\z/)
    expect(account.hooks.where(app_id: 'stripe')).to be_empty
  end

  it 'does not exchange a code after the configured environment changes' do
    allow(Integrations::Stripe::Oauth).to receive(:livemode?).and_return(true)
    expect(strategy).not_to receive(:get_token)
    get '/stripe/callback', params: { state: state, code: 'authorization-code' }
    expect(response).to have_http_status(:bad_request)
  end
end
