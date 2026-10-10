require 'rails_helper'

RSpec.describe AgentSessions::DailyLogoutService do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:role) { create(:custom_role, account: account) }
  let(:seller) { create(:user, account: account) }
  let(:manager) { create(:user, account: account) }
  let(:service) { described_class.new(account: account) }
  let(:config) { { 'enabled' => true, 'inbox_id' => inbox.id, 'custom_role_id' => role.id, 'time' => '20:00', 'timezone' => 'America/Sao_Paulo' } }

  before do
    travel_to Time.zone.parse('2026-10-11 22:59:00 UTC')
    create(:inbox_member, inbox: inbox, user: seller)
    create(:inbox_member, inbox: inbox, user: manager)
    seller.account_users.find_by!(account: account).update!(custom_role: role)
    account.update!(settings: account.settings.merge('daily_agent_logout' => config))
    seller.create_new_auth_token('web')
    seller.create_new_auth_token('mobile')
    manager.create_new_auth_token('manager')
    seller.user_sessions.create!(client_id: 'web')
    seller.user_sessions.create!(client_id: 'mobile')
    allow(ActionCable.server).to receive(:broadcast)
  end

  it 'revokes seller web and mobile sessions at 20:00 but preserves API tokens and managers' do
    api_token = seller.access_token.token
    service.perform
    expect(seller.reload.tokens.keys).to contain_exactly('web', 'mobile')
    travel 1.minute
    service.perform
    expect(seller.reload.tokens).to be_empty
    expect(seller.user_sessions).to be_empty
    expect(seller.account_users.find_by!(account: account)).to be_offline
    expect(seller.access_token.reload.token).to eq(api_token)
    expect(manager.reload.tokens).to have_key('manager')
    expect(ActionCable.server).to have_received(:broadcast).with(
      seller.pubsub_token, { event: 'user:logout', data: { client_ids: %w[web mobile] } }
    )
  end

  it 'preserves a new login when the scheduler runs again on the same day' do
    travel 1.minute
    service.perform
    travel 1.minute
    headers = seller.reload.create_new_auth_token('new-login')
    seller.user_sessions.create!(client_id: 'new-login')
    service.perform
    expect(seller.reload.valid_token?(headers['access-token'], 'new-login')).to be true
    expect(seller.user_sessions.pluck(:client_id)).to eq(['new-login'])
  end

  it 'marks a seller with no remaining sessions offline as well' do
    seller.update!(tokens: {})
    travel 1.minute
    service.perform
    expect(seller.account_users.find_by!(account: account)).to be_offline
  end

  it 'preserves post-cutoff sessions when the first execution is delayed' do
    travel 2.minutes
    seller.create_new_auth_token('new-login')
    seller.user_sessions.create!(client_id: 'new-login')
    service.perform
    expect(seller.reload.tokens.keys).to eq(['new-login'])
    expect(ActionCable.server).to have_received(:broadcast).with(
      seller.pubsub_token, { event: 'user:logout', data: { client_ids: %w[web mobile] } }
    )
  end

  it 'fails without revoking sessions when the configured role belongs to another account' do
    account.update!(settings: account.settings.merge('daily_agent_logout' => config.merge('custom_role_id' => create(:custom_role).id)))
    travel 1.minute
    expect { service.perform }.to raise_error(ActiveRecord::RecordNotFound)
    expect(seller.reload.tokens.keys).to contain_exactly('web', 'mobile')
  end
end
