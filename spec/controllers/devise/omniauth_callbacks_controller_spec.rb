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
  end
end
