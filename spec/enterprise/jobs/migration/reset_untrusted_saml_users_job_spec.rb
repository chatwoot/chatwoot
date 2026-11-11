require 'rails_helper'

RSpec.describe Migration::ResetUntrustedSamlUsersJob do
  let(:account) { create(:account) }
  let(:other_account) { create(:account) }
  let!(:saml_settings) { create(:account_saml_settings, account: account) }
  let!(:user) { create(:user, account: account, provider: 'saml') }

  before do
    account.enable_features!('saml')
    other_account.enable_features!('saml')
  end

  it 'keeps users who belong to one SAML account' do
    described_class.perform_now

    expect(user.reload.provider).to eq('saml')
  end

  it 'keeps users whose accounts all trust the same identity provider' do
    create(:account_saml_settings, account: other_account, certificate: saml_settings.certificate)
    user.account_users.create!(account: other_account, role: :agent)

    described_class.perform_now

    expect(user.reload.provider).to eq('saml')
  end

  it 'resets users whose accounts do not all trust the same identity provider' do
    create(:account_saml_settings, account: other_account)
    user.account_users.create!(account: other_account, role: :agent)

    described_class.perform_now

    expect(user.reload.provider).to eq('email')
  end

  it 'resets users whose account no longer uses SAML' do
    saml_settings.destroy!

    described_class.perform_now

    expect(user.reload.provider).to eq('email')
  end
end
