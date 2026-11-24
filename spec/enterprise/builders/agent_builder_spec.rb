require 'rails_helper'

RSpec.describe AgentBuilder do
  let(:email) { 'agent@example.com' }
  let(:name) { 'Test Agent' }
  let(:account) { create(:account) }
  let!(:inviter) { create(:user, account: account, role: 'administrator') }
  let(:builder) do
    described_class.new(
      email: email,
      name: name,
      account: account,
      inviter: inviter
    )
  end

  describe '#perform with SAML enabled' do
    let(:saml_settings) do
      create(:account_saml_settings, account: account)
    end

    before { saml_settings }

    context 'when user does not exist' do
      it 'creates a new user with SAML provider' do
        expect { builder.perform }.to change(User, :count).by(1)

        user = User.from_email(email)
        expect(user.provider).to eq('saml')
      end

      it 'creates user with correct attributes' do
        user = builder.perform

        expect(user.email).to eq(email)
        expect(user.name).to eq(name)
        expect(user.provider).to eq('saml')
        expect(user.encrypted_password).to be_present
      end

      it 'adds user to the account with correct role' do
        user = builder.perform
        account_user = AccountUser.find_by(user: user, account: account)

        expect(account_user).to be_present
        expect(account_user.role).to eq('agent')
        expect(account_user.inviter).to eq(inviter)
      end
    end

    context 'when user already exists with email provider' do
      let!(:existing_user) { create(:user, email: email, provider: 'email') }

      it 'does not create a new user' do
        expect { builder.perform }.not_to change(User, :count)
      end

      it 'converts existing user to SAML provider' do
        expect(existing_user.provider).to eq('email')

        builder.perform

        expect(existing_user.reload.provider).to eq('saml')
      end

      it 'adds existing user to the account' do
        user = builder.perform
        account_user = AccountUser.find_by(user: user, account: account)

        expect(account_user).to be_present
        expect(account_user.inviter).to eq(inviter)
      end
    end

    context 'when user already belongs to another account' do
      let(:other_account) { create(:account) }
      let!(:existing_user) { create(:user, email: email, account: other_account) }

      before do
        account.enable_features!('saml')
        other_account.enable_features!('saml')
        create(:account_user, account: other_account, user: inviter, role: :administrator)
      end

      it 'adds the user when the other account trusts the same identity provider' do
        create(:account_saml_settings, account: other_account, certificate: saml_settings.certificate)

        builder.perform

        expect(existing_user.reload.accounts).to include(account)
        expect(existing_user.provider).to eq('saml')
      end

      it 'refuses the user when SAML is disabled for this account' do
        create(:account_saml_settings, account: other_account, certificate: saml_settings.certificate)
        account.disable_features!('saml')

        expect { builder.perform }.to raise_error(ActiveRecord::RecordInvalid)
        expect(existing_user.reload.provider).to eq('email')
      end

      it 'refuses the user when the other account does not trust the same identity provider' do
        expect { builder.perform }.to raise_error(ActiveRecord::RecordInvalid)
        expect(existing_user.reload.accounts).not_to include(account)
      end

      it 'refuses the user when the inviter does not administer the other account' do
        create(:account_saml_settings, account: other_account, certificate: saml_settings.certificate)
        inviter.account_users.find_by(account: other_account).destroy!

        expect { builder.perform }.to raise_error(ActiveRecord::RecordInvalid)
        expect(existing_user.reload.accounts).not_to include(account)
      end

      it 'refuses the user when the inviter is only an agent in the other account' do
        create(:account_saml_settings, account: other_account, certificate: saml_settings.certificate)
        inviter.account_users.find_by(account: other_account).update!(role: :agent)

        expect { builder.perform }.to raise_error(ActiveRecord::RecordInvalid)
        expect(existing_user.reload.accounts).not_to include(account)
      end
    end

    context 'when user already exists with SAML provider' do
      let!(:existing_user) { create(:user, email: email, provider: 'saml') }

      it 'does not change the provider' do
        expect { builder.perform }.not_to(change { existing_user.reload.provider })
      end

      it 'still adds user to the account' do
        user = builder.perform
        account_user = AccountUser.find_by(user: user, account: account)

        expect(account_user).to be_present
      end
    end
  end

  describe '#perform without SAML' do
    context 'when user does not exist' do
      it 'creates a new user with email provider (default behavior)' do
        expect { builder.perform }.to change(User, :count).by(1)

        user = User.from_email(email)
        expect(user.provider).to eq('email')
      end
    end

    context 'when user already exists' do
      let!(:existing_user) { create(:user, email: email, provider: 'email') }

      it 'does not change the existing user provider' do
        expect { builder.perform }.not_to(change { existing_user.reload.provider })
      end
    end
  end

  describe '#perform with different account configurations' do
    context 'when account has no SAML settings' do
      # No saml_settings created for this account

      it 'treats account as non-SAML enabled' do
        user = builder.perform
        expect(user.provider).to eq('email')
      end
    end

    context 'when SAML settings are deleted after user creation' do
      let(:saml_settings) do
        create(:account_saml_settings, account: account)
      end
      let(:existing_user) { create(:user, email: email, provider: 'saml') }

      before do
        saml_settings
        existing_user
      end

      it 'does not affect existing SAML users when adding to account' do
        saml_settings.destroy!

        user = builder.perform
        expect(user.provider).to eq('saml') # Unchanged
      end
    end
  end
end
