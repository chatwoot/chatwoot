require 'rails_helper'

RSpec.describe 'DeviseOverrides::OmniauthCallbacksController', type: :request do
  let(:account_builder) { double }
  let(:user_double) { instance_double(User) }

  before do
    allow_any_instance_of(DeviseOverrides::OmniauthCallbacksController).to receive(:confirmable_enabled?).and_return(false)
    allow(GlobalConfigService).to receive(:load).with('ENABLE_ACCOUNT_SIGNUP', 'false').and_return('true')
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] = nil
  end

  def set_omniauth_config(for_email = 'test@example.com')
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: 'google',
      uid: '123545',
      info: {
        name: 'test',
        email: for_email,
        image: 'https://example.com/image.jpg',
        email_verified: true
      }
    )
  end

  describe '#omniauth_success' do
    it 'allows signup' do
      with_modified_env ENABLE_ACCOUNT_SIGNUP: 'true', FRONTEND_URL: 'http://www.example.com' do
        set_omniauth_config('test_not_preset@example.com')
        allow(AccountBuilder).to receive(:new).and_return(account_builder)
        allow(account_builder).to receive(:perform).and_return([user_double, double('account')])
        allow(user_double).to receive(:set_reset_password_token).and_return('reset-token')
        allow(user_double).to receive(:skip_confirmation!).and_return(true)
        allow(Avatar::AvatarFromUrlJob).to receive(:perform_later).and_return(true)

        get '/omniauth/google_oauth2/callback'

        # expect a 302 redirect to auth/google_oauth2/callback
        expect(response).to redirect_to('http://www.example.com/auth/google_oauth2/callback')
        follow_redirect!

        expect(AccountBuilder).to have_received(:new).with({
                                                             account_name: 'example',
                                                             user_full_name: 'test',
                                                             email: 'test_not_preset@example.com',
                                                             locale: I18n.locale,
                                                             confirmed: true
                                                           })
        expect(account_builder).to have_received(:perform)
      end
    end

    it 'blocks personal accounts signup' do
      with_modified_env ENABLE_ACCOUNT_SIGNUP: 'true', FRONTEND_URL: 'http://www.example.com' do
        set_omniauth_config('personal@gmail.com')
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
        allow(GlobalConfigService).to receive(:load).with('ENABLE_ACCOUNT_SIGNUP', 'false').and_return('false')
        set_omniauth_config('does-not-exist-for-sure@example.com')
        get '/omniauth/google_oauth2/callback'

        # expect a 302 redirect to auth/google_oauth2/callback
        expect(response).to redirect_to('http://www.example.com/auth/google_oauth2/callback')
        follow_redirect!

        # expect a 302 redirect to app/login with error disallowing signup
        expect(response).to redirect_to(%r{/app/login\?error=no-account-found$})
      end
    end

    it 'allows login' do
      user = create(:user, email: 'test@example.com')
      allow_any_instance_of(User).to receive(:generate_sso_auth_token).and_return('test-token')
      allow_any_instance_of(User).to receive(:skip_confirmation!).and_return(true)
      allow(User).to receive(:find_by).with(email: 'test@example.com').and_return(user)
      set_omniauth_config('test@example.com')

      with_modified_env FRONTEND_URL: 'http://www.example.com' do
        get '/omniauth/google_oauth2/callback'
        # expect a 302 redirect to auth/google_oauth2/callback
        expect(response).to redirect_to('http://www.example.com/auth/google_oauth2/callback')

        follow_redirect!
        expect(response).to redirect_to('http://www.example.com/app/login?email=test%2540example.com&sso_auth_token=test-token')
      end
    end

    # from a line coverage point of view this may seem redundant
    # but to ensure that the logic allows for existing users even if they have a gmail account
    # we need to test this explicitly
    it 'allows personal account login' do
      user = create(:user, email: 'personal-existing@gmail.com')
      allow(User).to receive(:find_by).with(email: 'personal-existing@gmail.com').and_return(user)
      allow_any_instance_of(User).to receive(:generate_sso_auth_token).and_return('some-token')
      set_omniauth_config('personal-existing@gmail.com')

      with_modified_env FRONTEND_URL: 'http://www.example.com' do
        get '/omniauth/google_oauth2/callback'
        # expect a 302 redirect to auth/google_oauth2/callback
        expect(response).to redirect_to('http://www.example.com/auth/google_oauth2/callback')

        follow_redirect!
        expect(response).to redirect_to('http://www.example.com/app/login?email=personal-existing%2540gmail.com&sso_auth_token=some-token')
      end
    end
  end
end
