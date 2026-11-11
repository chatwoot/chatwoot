require 'rails_helper'

RSpec.describe Keycloak::RoleSyncService do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account, role: :agent) }
  let(:account_user) { user.account_users.find_by(account: account) }

  it 'syncs mapped permissions from keycloak roles' do
    described_class.new(user: user, keycloak_roles: ['keycloak:chatwoot_manager']).perform

    state = user.reload.custom_attributes['keycloak']
    expect(state['roles']).to eq(['chatwoot_manager'])
    expect(state['permissions']).to include('can_delete_conversations', 'can_manage_automations')
    expect(account_user.reload.permissions).to include('agent', 'can_export_contacts')
  end

  it 'promotes users mapped to the admin role' do
    described_class.new(user: user, keycloak_roles: ['chatwoot_admin']).perform

    expect(account_user.reload).to be_administrator
  end

  it 'demotes an admin whose keycloak roles are not mapped' do
    admin = create(:user, account: account, role: :administrator)
    described_class.new(user: admin, keycloak_roles: ['something_else']).perform

    admin_account_user = admin.account_users.find_by(account: account)
    expect(admin_account_user).to be_agent
    expect(admin.reload.custom_attributes.dig('keycloak', 'permissions')).to eq([])
    expect(admin_account_user.has_permission?(:can_delete_conversations)).to be(false)
  end

  it 'unions permissions across multiple roles' do
    described_class.new(user: user, keycloak_roles: %w[chatwoot_agent chatwoot_manager]).perform

    expect(user.reload.custom_attributes.dig('keycloak', 'permissions')).to include('can_view_reports', 'can_view_all_contacts')
  end
end

RSpec.describe Keycloak::RoleExtractor do
  def jwt_payload(claims)
    "header.#{Base64.urlsafe_encode64(claims.to_json, padding: false)}.sig"
  end

  it 'reads roles from id token claims and the access token' do
    auth_hash = {
      'extra' => { 'raw_info' => { 'realm_access' => { 'roles' => ['chatwoot_agent'] } } },
      'credentials' => { 'token' => jwt_payload({ realm_access: { roles: ['chatwoot_manager'] } }) }
    }

    expect(described_class.new(auth_hash).roles).to contain_exactly('chatwoot_agent', 'chatwoot_manager')
  end

  it 'returns no roles for a malformed access token' do
    expect(described_class.new({ 'credentials' => { 'token' => 'garbage' } }).roles).to eq([])
  end
end

RSpec.describe Keycloak::LoginService do
  let(:account) { create(:account) }

  def auth_hash(email:, verified: true, roles: ['chatwoot_manager'])
    {
      'info' => { 'email' => email, 'name' => 'Kc User', 'email_verified' => verified },
      'extra' => { 'raw_info' => { 'realm_access' => { 'roles' => roles } } },
      'credentials' => {}
    }
  end

  it 'signs in an existing user and syncs the roles' do
    user = create(:user, account: account, role: :agent)
    described_class.new(auth_hash(email: user.email)).perform

    expect(user.reload.custom_attributes.dig('keycloak', 'roles')).to eq(['chatwoot_manager'])
  end

  it 'provisions unknown users into the default account' do
    account
    user = described_class.new(auth_hash(email: 'new.kc.user@example.com')).perform

    expect(user.account_users.first.account).to eq(account)
    expect(user.custom_attributes.dig('keycloak', 'permissions')).to include('can_view_reports')
  end

  it 'rejects unverified emails' do
    expect { described_class.new(auth_hash(email: 'x@example.com', verified: false)).perform }
      .to raise_error(described_class::LoginError, 'email-not-verified')
  end
end
