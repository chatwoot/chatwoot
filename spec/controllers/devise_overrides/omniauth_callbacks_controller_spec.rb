require 'rails_helper'

RSpec.describe DeviseOverrides::OmniauthCallbacksController, type: :controller do
  let(:account) { create(:account) }
  let(:email) { 'saml.user@example.com' }

  before do
    # Set up OmniAuth test mode
    OmniAuth.config.test_mode = true
    request.env['devise.mapping'] = Devise.mappings[:user]
  end

  after do
    OmniAuth.config.test_mode = false
  end

  describe 'POST #saml' do
    let(:auth_hash) do
      OmniAuth::AuthHash.new(
        provider: 'saml',
        uid: 'saml-uid-123',
        info: {
          email: email,
          name: 'SAML User',
          first_name: 'SAML',
          last_name: 'User'
        },
        extra: {
          raw_info: {
            groups: ['Administrators']
          }
        }
      )
    end

    context 'successful SAML authentication' do
      before do
        # Set up session with auth data as DeviseTokenAuth would
        session['dta.omniauth.auth'] = auth_hash.to_hash
        session[:saml_account_id] = account.id

        # Enable SAML for the account
        create(:account_saml_settings, account: account, enabled: true)
      end

      context 'when user does not exist' do
        it 'creates a new user' do
          expect do
            post :saml
          end.to change(User, :count).by(1)
        end

        it 'redirects to login with SSO token' do
          post :saml

          User.from_email(email)
          expect(response).to redirect_to(%r{/app/login\?email=.*&sso_auth_token=})
        end

        it 'associates user with account' do
          post :saml

          user = User.from_email(email)
          expect(user.accounts).to include(account)
        end
      end

      context 'when user already exists' do
        let!(:existing_user) { create(:user, email: email) }

        it 'does not create a new user' do
          expect do
            post :saml
          end.not_to change(User, :count)
        end

        it 'redirects to login with SSO token' do
          post :saml

          expect(response).to redirect_to(%r{/app/login\?email=.*&sso_auth_token=})
        end

        it 'adds user to account if not already added' do
          expect(existing_user.accounts).not_to include(account)

          post :saml

          expect(existing_user.reload.accounts).to include(account)
        end
      end

      context 'without account_id' do
        before do
          session.delete(:saml_account_id)
        end

        it 'still processes the authentication' do
          post :saml

          expect(response).to redirect_to(%r{/app/login})
        end
      end
    end

    context 'SAML not enabled for account' do
      before do
        session['dta.omniauth.auth'] = auth_hash.to_hash
        session[:saml_account_id] = account.id

        # SAML is disabled for the account
        create(:account_saml_settings, account: account, enabled: false)
      end

      it 'redirects with error' do
        post :saml

        expect(response).to redirect_to(%r{/app/login\?error=saml-not-enabled})
      end

      it 'does not create a user' do
        expect do
          post :saml
        end.not_to change(User, :count)
      end
    end

    context 'without auth hash' do
      before do
        session.delete('dta.omniauth.auth')
      end

      it 'redirects to login' do
        post :saml

        expect(response).to redirect_to(%r{/app/login})
      end
    end
  end

  describe 'GET #redirect_callbacks' do
    let(:auth_hash) do
      OmniAuth::AuthHash.new(
        provider: 'saml',
        uid: 'saml-uid-123',
        info: {
          email: email,
          name: 'SAML User'
        }
      )
    end

    before do
      request.env['omniauth.auth'] = auth_hash
      request.env['omniauth.params'] = {
        'resource_class' => 'User',
        'account_id' => account.id.to_s
      }
    end

    context 'for SAML provider' do
      it 'stores auth data in session' do
        get :redirect_callbacks, params: { provider: 'saml' }

        expect(session['dta.omniauth.auth']).to eq(auth_hash.except('extra'))
        expect(session['dta.omniauth.params']).to include('account_id' => account.id.to_s)
      end

      it 'redirects with 303 status for SAML' do
        get :redirect_callbacks, params: { provider: 'saml' }

        expect(response).to have_http_status(303)
        expect(response).to redirect_to(%r{/auth/saml/callback})
      end
    end

    context 'for non-SAML provider' do
      it 'redirects with 307 status' do
        get :redirect_callbacks, params: { provider: 'google_oauth2' }

        expect(response).to have_http_status(307)
        expect(response).to redirect_to(%r{/auth/google_oauth2/callback})
      end
    end
  end

  describe '#get_resource_from_auth_hash' do
    let(:auth_hash) do
      {
        'provider' => 'saml',
        'info' => {
          'email' => email
        }
      }
    end

    before do
      allow(controller).to receive(:auth_hash).and_return(auth_hash)
    end

    context 'for SAML provider' do
      it 'uses from_email to find user' do
        existing_user = create(:user, email: email.upcase) # Test case insensitivity

        controller.send(:get_resource_from_auth_hash)

        expect(controller.instance_variable_get(:@resource)).to eq(existing_user)
      end
    end

    context 'for non-SAML provider' do
      let(:auth_hash) do
        {
          'provider' => 'google_oauth2',
          'info' => {
            'email' => email
          }
        }
      end

      it 'uses where query to find user' do
        existing_user = create(:user, email: email)

        controller.send(:get_resource_from_auth_hash)

        expect(controller.instance_variable_get(:@resource)).to eq(existing_user)
      end
    end
  end
end
