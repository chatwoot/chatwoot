require 'rails_helper'

RSpec.describe 'Stripe Integration API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let!(:hook) { create(:integrations_hook, app_id: 'stripe', account: account, reference_id: 'acct_sandbox', access_token: 'private-credentials') }
  let(:path) { "/api/v1/accounts/#{account.id}/integrations/stripe" }
  let(:conversation) { create(:conversation, account: account) }
  let(:summary) { instance_double(Integrations::Stripe::CustomerSummary, perform: { customers: [] }) }

  before do
    allow(Integrations::Stripe::Oauth).to receive(:configured?).and_return(true)
  end

  it 'returns account details to administrators without credentials' do
    get path, headers: admin.create_new_auth_token
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to include('account_id' => 'acct_sandbox', 'mode' => 'sandbox')
    expect(response.body).not_to include('private-credentials', 'access_token', 'refresh_token')
  end

  it 'rejects unauthenticated access' do
    get path
    expect(response).to have_http_status(:unauthorized)
  end

  it 'returns the authorization date rather than hook creation or token update dates' do
    connected_at = 2.days.ago.iso8601
    hook.update!(settings: { 'connected_at' => connected_at })
    get path, headers: admin.create_new_auth_token
    expect(response.parsed_body['connected_at']).to eq(connected_at)
  end

  it 'reports the stored live environment without exposing credentials' do
    hook.update!(settings: { 'livemode' => true })
    get path, headers: admin.create_new_auth_token
    expect(response.parsed_body).to include('mode' => 'live')
    expect(response.body).not_to include('private-credentials', 'access_token', 'refresh_token')
  end

  it 'prevents agents from reading installation details or connecting' do
    headers = agent.create_new_auth_token
    get path, headers: headers
    expect(response).to have_http_status(:unauthorized)
    post "#{path}/auth", headers: headers
    expect(response).to have_http_status(:unauthorized)
  end

  it 'starts OAuth for the current account administrator' do
    expect(Integrations::Stripe::Oauth).to receive(:authorize_url).with(account: account, user: admin).and_return('https://marketplace.stripe.com/test')
    post "#{path}/auth", headers: admin.create_new_auth_token
    expect(response.parsed_body).to eq('url' => 'https://marketplace.stripe.com/test')
  end

  it 'allows administrators to disconnect only their own hook' do
    other = create(:integrations_hook, app_id: 'stripe')
    delete path, headers: admin.create_new_auth_token
    expect(response).to have_http_status(:no_content)
    expect(Integrations::Hook.exists?(hook.id)).to be false
    expect(Integrations::Hook.exists?(other.id)).to be true
  end

  it 'prevents agents from disconnecting' do
    delete path, headers: agent.create_new_auth_token
    expect(response).to have_http_status(:unauthorized)
    expect(hook.reload).to be_present
  end

  it 'uses the authorized conversation contact rather than a supplied email' do
    expect(Integrations::Stripe::CustomerSummary).to receive(:new)
      .with(connection: instance_of(Integrations::Stripe::Connection), contact: conversation.contact).and_return(summary)
    get "#{path}/customer", params: { conversation_id: conversation.display_id, email: 'unrelated@example.com' }, headers: admin.create_new_auth_token
    expect(response).to have_http_status(:ok)
  end

  it 'denies agents without access to the conversation inbox' do
    expect(Integrations::Stripe::CustomerSummary).not_to receive(:new)
    get "#{path}/customer", params: { conversation_id: conversation.display_id }, headers: agent.create_new_auth_token
    expect(response).to have_http_status(:unauthorized)
  end

  it 'allows agents to read billing details for an accessible conversation' do
    create(:inbox_member, inbox: conversation.inbox, user: agent)
    allow(Integrations::Stripe::CustomerSummary).to receive(:new).and_return(summary)
    get "#{path}/customer", params: { conversation_id: conversation.display_id }, headers: agent.create_new_auth_token
    expect(response).to have_http_status(:ok)
  end

  it 'does not look up a conversation in another account' do
    other = create(:conversation)
    get "#{path}/customer", params: { conversation_id: other.display_id }, headers: admin.create_new_auth_token
    expect(response).to have_http_status(:not_found)
  end

  it 'returns a safe error on provider failure' do
    allow(Integrations::Stripe::CustomerSummary).to receive(:new).and_return(summary)
    allow(summary).to receive(:perform).and_raise(Stripe::APIConnectionError.new('sensitive provider details'))
    get "#{path}/customer", params: { conversation_id: conversation.display_id }, headers: admin.create_new_auth_token
    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body).to eq('error' => 'stripe_unavailable')
  end

  it 'disables endpoints when installation settings are missing' do
    allow(Integrations::Stripe::Oauth).to receive(:configured?).and_return(false)
    get path, headers: admin.create_new_auth_token
    expect(response).to have_http_status(:not_found)
  end
end
