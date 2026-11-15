require 'rails_helper'

RSpec.describe 'DeviseOverrides::OmniauthCallbacksController', type: :request do
  let(:account_builder) { double }
  let(:user_double) { object_double(:user) }
  let(:email_validation_service) { instance_double(Account::SignUpEmailValidationService) }

  def set_omniauth_config(for_email = 'test@example.com')
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: 'google',
      uid: '123545',
      info: {
        name: 'test',
        email: for_email,
        image: 'https://example.com/image.jpg'
      }
    )
  end

  before do
    allow(Account::SignUpEmailValidationService).to receive(:new).and_return(email_validation_service)
  end

  describe '#omniauth_sucess' do
    before do
      GlobalConfig.clear_cache
    end

    it 'allows signup' do
      with_modified_env ENABLE_ACCOUNT_SIGNUP: 'true', FRONTEND_URL: 'http://www.example.com' do
        set_omniauth_config('test_not_preset@example.com')
        allow(AccountBuilder).to receive(:new).and_return(account_builder)
        allow(account_builder).to receive(:perform).and_return(user_double)
        allow(Avatar::AvatarFromUrlJob).to receive(:perform_later).and_return(true)
        allow(email_validation_service).to receive(:perform).and_return(true)

        get '/omniauth/google_oauth2/callback'

        # expect a 302 redirect to auth/google_oauth2/callback
        expect(response).to redirect_to('http://www.example.com/auth/google_oauth2/callback')
        follow_redirect!

        expect(AccountBuilder).to have_received(:new).with({
                                                             account_name: 'example',
                                                             user_full_name: 'test',
                                                             email: 'test_not_preset@example.com',
                                                             locale: I18n.locale,
                                                             confirmed: nil
                                                           })
        expect(account_builder).to have_received(:perform)
      end
    end

    it 'blocks personal accounts signup' do
      with_modified_env ENABLE_ACCOUNT_SIGNUP: 'true', FRONTEND_URL: 'http://www.example.com' do
        set_omniauth_config('personal@gmail.com')
        allow(email_validation_service).to receive(:perform).and_raise(CustomExceptions::Account::InvalidEmail.new({ valid: false, disposable: nil }))

        get '/omniauth/google_oauth2/callback'

        # expect a 302 redirect to auth/google_oauth2/callback
        expect(response).to redirect_to('http://www.example.com/auth/google_oauth2/callback')
        follow_redirect!

        # expect a 302 redirect to app/login with error disallowing personal accounts
        expect(response).to redirect_to(%r{/app/login\?error=business-account-only$})
      end
    end

    it 'blocks personal accounts signup with different Gmail case variations' do
      with_modified_env ENABLE_ACCOUNT_SIGNUP: 'true', FRONTEND_URL: 'http://www.example.com' do
        # Test different case variations of Gmail
        ['personal@Gmail.com', 'personal@GMAIL.com', 'personal@Gmail.COM'].each do |email|
          set_omniauth_config(email)
          allow(email_validation_service).to receive(:perform).and_raise(CustomExceptions::Account::InvalidEmail.new({ valid: false,
                                                                                                                       disposable: nil }))

          get '/omniauth/google_oauth2/callback'

          # expect a 302 redirect to auth/google_oauth2/callback
          expect(response).to redirect_to('http://www.example.com/auth/google_oauth2/callback')
          follow_redirect!

          # expect a 302 redirect to app/login with error disallowing personal accounts
          expect(response).to redirect_to(%r{/app/login\?error=business-account-only$})
        end
      end
    end

    # This test does not affect line coverage, but it is important to ensure that the logic
    # does not allow any signup if the ENV explicitly disables it
    it 'blocks signup if ENV disabled' do
      with_modified_env ENABLE_ACCOUNT_SIGNUP: 'false', FRONTEND_URL: 'http://www.example.com' do
        set_omniauth_config('does-not-exist-for-sure@example.com')
        allow(email_validation_service).to receive(:perform).and_return(true)

        get '/omniauth/google_oauth2/callback'

        # expect a 302 redirect to auth/google_oauth2/callback
        expect(response).to redirect_to('http://www.example.com/auth/google_oauth2/callback')
        follow_redirect!

        # expect a 302 redirect to app/login with error disallowing signup
        expect(response).to redirect_to(%r{/app/login\?error=no-account-found$})
      end
    end

    it 'blocks signup if config is stored as boolean false' do
      GlobalConfig.clear_cache
      InstallationConfig.where(name: 'ENABLE_ACCOUNT_SIGNUP').delete_all
      InstallationConfig.create!(name: 'ENABLE_ACCOUNT_SIGNUP', value: false, locked: false)

      with_modified_env FRONTEND_URL: 'http://www.example.com' do
        set_omniauth_config('does-not-exist-for-sure@example.com')
        allow(email_validation_service).to receive(:perform).and_return(true)

        get '/omniauth/google_oauth2/callback'

        expect(response).to redirect_to('http://www.example.com/auth/google_oauth2/callback')
        follow_redirect!
        expect(response).to redirect_to(%r{/app/login\?error=no-account-found$})
      end
    ensure
      InstallationConfig.where(name: 'ENABLE_ACCOUNT_SIGNUP').delete_all
      GlobalConfig.clear_cache
    end

    context 'with a Shopify pending installation' do
      let(:pending_token) { 'a' * 32 }
      let(:redirect_url) { "settings/integrations/shopify?shopify_pending_install=#{pending_token}" }
      let(:shopify_signup_service) { instance_double(Shopify::SignupService) }
      let(:shopify_user) { create(:user, email: 'created-shopify@example.com') }
      let(:shopify_account) { create(:account) }

      before do
        set_omniauth_config('new-shopify@example.com')
        allow(email_validation_service).to receive(:perform).and_return(true)
        allow(Shopify::FeatureGate).to receive(:enabled?).and_return(true)
        allow(Shopify::PendingInstallation).to receive(:pending?).with(token: pending_token).and_return(true)
        allow(Shopify::SignupService).to receive(:new).and_return(shopify_signup_service)
        allow(shopify_signup_service).to receive(:perform).and_return([shopify_user, shopify_account])
        allow(Avatar::AvatarFromUrlJob).to receive(:perform_later)
      end

      it 'allows a valid installation when public signup is disabled and uses the Shopify service' do
        with_modified_env ENABLE_ACCOUNT_SIGNUP: 'false', FRONTEND_URL: 'http://www.example.com' do
          get '/omniauth/google_oauth2/callback', params: { state: redirect_url }
          follow_redirect!

          expect(Shopify::SignupService).to have_received(:new).with(hash_including(shopify_pending_install_token: pending_token))
          expect(shopify_signup_service).to have_received(:perform)
          expect(response).to redirect_to(%r{/app/auth/password/edit\?config=default&reset_password_token=.+})
        end
      end

      it 'uses the Shopify service when public signup is enabled too' do
        with_modified_env ENABLE_ACCOUNT_SIGNUP: 'true', FRONTEND_URL: 'http://www.example.com' do
          get '/omniauth/google_oauth2/callback', params: { state: redirect_url }
          follow_redirect!

          expect(Shopify::SignupService).to have_received(:new).with(hash_including(shopify_pending_install_token: pending_token))
          expect(shopify_signup_service).to have_received(:perform)
        end
      end

      it 'rejects an expired or invalid installation when public signup is disabled' do
        allow(Shopify::PendingInstallation).to receive(:pending?).with(token: pending_token).and_return(false)

        with_modified_env ENABLE_ACCOUNT_SIGNUP: 'false', FRONTEND_URL: 'http://www.example.com' do
          get '/omniauth/google_oauth2/callback', params: { state: redirect_url }
          follow_redirect!

          expect(Shopify::SignupService).not_to have_received(:new)
          expect(response).to redirect_to(%r{/app/login\?error=no-account-found$})
        end
      end

      it 'rejects Shopify signup when its feature is disabled' do
        allow(Shopify::FeatureGate).to receive(:enabled?).and_return(false)

        with_modified_env ENABLE_ACCOUNT_SIGNUP: 'false', FRONTEND_URL: 'http://www.example.com' do
          get '/omniauth/google_oauth2/callback', params: { state: redirect_url }
          follow_redirect!

          expect(Shopify::SignupService).not_to have_received(:new)
          expect(response).to redirect_to(%r{/app/login\?error=no-account-found$})
        end
      end
    end

    it 'allows login' do
      with_modified_env FRONTEND_URL: 'http://www.example.com' do
        create(:user, email: 'test@example.com')
        set_omniauth_config('test@example.com')

        get '/omniauth/google_oauth2/callback'
        # expect a 302 redirect to auth/google_oauth2/callback
        expect(response).to redirect_to('http://www.example.com/auth/google_oauth2/callback')

        follow_redirect!
        expect(response).to redirect_to(%r{/app/login\?email=.+&sso_auth_token=.+$})

        # expect app/login page to respond with 200 and render
        follow_redirect!
        expect(response).to have_http_status(:ok)
      end
    end

    # from a line coverage point of view this may seem redundant
    # but to ensure that the logic allows for existing users even if they have a gmail account
    # we need to test this explicitly
    it 'allows personal account login' do
      with_modified_env FRONTEND_URL: 'http://www.example.com' do
        create(:user, email: 'personal-existing@gmail.com')
        set_omniauth_config('personal-existing@gmail.com')

        get '/omniauth/google_oauth2/callback'
        # expect a 302 redirect to auth/google_oauth2/callback
        expect(response).to redirect_to('http://www.example.com/auth/google_oauth2/callback')

        follow_redirect!
        expect(response).to redirect_to(%r{/app/login\?email=.+&sso_auth_token=.+$})

        # expect app/login page to respond with 200 and render
        follow_redirect!
        expect(response).to have_http_status(:ok)
      end
    end

    it 'resets password for an unconfirmed persisted user on OAuth login' do
      with_modified_env FRONTEND_URL: 'http://www.example.com' do
        user = create(:user, email: 'unconfirmed-oauth@example.com', skip_confirmation: false)
        original_password_digest = user.encrypted_password
        set_omniauth_config('unconfirmed-oauth@example.com')

        get '/omniauth/google_oauth2/callback'
        expect(response).to redirect_to('http://www.example.com/auth/google_oauth2/callback')
        follow_redirect!

        user.reload
        expect(user).to be_confirmed
        expect(user.encrypted_password).not_to eq(original_password_digest)
      end
    end
  end
end
