require 'rails_helper'

RSpec.describe SamlUserBuilder do
  let(:email) { 'saml.user@example.com' }
  let(:auth_hash) do
    {
      'provider' => 'saml',
      'uid' => 'saml-uid-123',
      'info' => {
        'email' => email,
        'name' => 'SAML User',
        'first_name' => 'SAML',
        'last_name' => 'User'
      },
      'extra' => {
        'raw_info' => {
          'groups' => %w[Administrators Users]
        }
      }
    }
  end
  let(:account) { create(:account) }
  let(:builder) { described_class.new(auth_hash, account.id) }

  describe '#perform' do
    context 'when user does not exist' do
      it 'creates a new user' do
        expect { builder.perform }.to change(User, :count).by(1)
      end

      it 'creates user with correct attributes' do
        user = builder.perform

        expect(user.email).to eq(email)
        expect(user.name).to eq('SAML User')
        expect(user.display_name).to eq('SAML')
        expect(user.provider).to eq('saml')
        expect(user.uid).to eq(email) # User model sets uid to email in before_validation callback
        expect(user.confirmed_at).to be_present
      end

      it 'creates user with a random password' do
        user = builder.perform
        expect(user.encrypted_password).to be_present
      end

      it 'adds user to the account' do
        user = builder.perform
        expect(user.accounts).to include(account)
      end

      it 'sets default role as agent' do
        user = builder.perform
        account_user = AccountUser.find_by(user: user, account: account)
        expect(account_user.role).to eq('agent')
      end

      context 'when name is not provided' do
        let(:auth_hash) do
          {
            'provider' => 'saml',
            'uid' => 'saml-uid-123',
            'info' => {
              'email' => email
            }
          }
        end

        it 'derives name from email' do
          user = builder.perform
          expect(user.name).to eq('saml.user')
        end
      end
    end

    context 'when user already exists' do
      let!(:existing_user) { create(:user, email: email) }

      it 'does not create a new user' do
        expect { builder.perform }.not_to change(User, :count)
      end

      it 'returns the existing user' do
        user = builder.perform
        expect(user).to eq(existing_user)
      end

      it 'adds existing user to the account if not already added' do
        user = builder.perform
        expect(user.accounts).to include(account)
      end

      it 'converts existing user to SAML' do
        expect(existing_user.provider).not_to eq('saml')

        builder.perform

        expect(existing_user.reload.provider).to eq('saml')
      end

      it 'does not change provider if user is already SAML' do
        existing_user.update!(provider: 'saml')

        expect { builder.perform }.not_to(change { existing_user.reload.provider })
      end

      it 'does not duplicate account association' do
        existing_user.account_users.create!(account: account, role: 'agent')

        expect { builder.perform }.not_to change(AccountUser, :count)
      end

      context 'when user is not confirmed' do
        let(:unconfirmed_email) { 'unconfirmed_saml_user@example.com' }
        let(:unconfirmed_auth_hash) do
          {
            'provider' => 'saml',
            'uid' => 'saml-uid-123',
            'info' => {
              'email' => unconfirmed_email,
              'name' => 'SAML User',
              'first_name' => 'SAML',
              'last_name' => 'User'
            },
            'extra' => {
              'raw_info' => {
                'groups' => %w[Administrators Users]
              }
            }
          }
        end
        let(:unconfirmed_builder) { described_class.new(unconfirmed_auth_hash, account.id) }
        let!(:existing_user) do
          user = build(:user, email: unconfirmed_email)
          user.confirmed_at = nil
          user.save!(validate: false)
          user
        end

        it 'confirms unconfirmed user after SAML authentication' do
          expect(existing_user.confirmed?).to be false

          unconfirmed_builder.perform

          expect(existing_user.reload.confirmed?).to be true
        end
      end

      context 'when user is already confirmed' do
        let!(:existing_user) { create(:user, email: email, confirmed_at: Time.current) }

        it 'keeps already confirmed user confirmed' do
          expect(existing_user.confirmed?).to be true
          original_confirmed_at = existing_user.confirmed_at

          builder.perform

          expect(existing_user.reload.confirmed?).to be true
          expect(existing_user.reload.confirmed_at).to be_within(2.seconds).of(original_confirmed_at)
        end
      end
    end

    context 'with role mappings' do
      let(:saml_settings) do
        create(:account_saml_settings,
               account: account,
               role_mappings: {
                 'Administrators' => { 'role' => 'administrator' },
                 'Agents' => { 'role' => 'agent' }
               })
      end

      before { saml_settings }

      it 'applies administrator role based on SAML groups' do
        user = builder.perform
        account_user = AccountUser.find_by(user: user, account: account)
        expect(account_user.role).to eq('administrator')
      end

      context 'with custom role mapping' do
        let!(:custom_role) { create(:custom_role, account: account) }
        let(:saml_settings) do
          create(:account_saml_settings,
                 account: account,
                 role_mappings: {
                   'Administrators' => { 'custom_role_id' => custom_role.id }
                 })
        end

        before { saml_settings }

        it 'applies custom role based on SAML groups' do
          user = builder.perform
          account_user = AccountUser.find_by(user: user, account: account)
          expect(account_user.custom_role_id).to eq(custom_role.id)
        end
      end

      context 'when user is not in any mapped groups' do
        let(:auth_hash) do
          {
            'provider' => 'saml',
            'uid' => 'saml-uid-123',
            'info' => {
              'email' => email,
              'name' => 'SAML User'
            },
            'extra' => {
              'raw_info' => {
                'groups' => ['UnmappedGroup']
              }
            }
          }
        end

        it 'keeps default agent role' do
          user = builder.perform
          account_user = AccountUser.find_by(user: user, account: account)
          expect(account_user.role).to eq('agent')
        end
      end
    end

    context 'with different group attribute names' do
      let(:auth_hash) do
        {
          'provider' => 'saml',
          'uid' => 'saml-uid-123',
          'info' => {
            'email' => email,
            'name' => 'SAML User'
          },
          'extra' => {
            'raw_info' => {
              'memberOf' => ['CN=Administrators,OU=Groups,DC=example,DC=com']
            }
          }
        }
      end

      it 'reads groups from memberOf attribute' do
        builder_instance = described_class.new(auth_hash, account_id: account.id)
        allow(builder_instance).to receive(:saml_groups).and_return(['CN=Administrators,OU=Groups,DC=example,DC=com'])
        user = builder_instance.perform
        expect(user).to be_persisted
      end
    end

    context 'when there are errors' do
      it 'returns unsaved user object when user creation fails' do
        allow(User).to receive(:create).and_return(User.new(email: email))
        user = builder.perform
        expect(user.persisted?).to be false
      end

      it 'does not create account association for failed user' do
        allow(User).to receive(:create).and_return(User.new(email: email))
        expect { builder.perform }.not_to change(AccountUser, :count)
      end
    end
  end
end
