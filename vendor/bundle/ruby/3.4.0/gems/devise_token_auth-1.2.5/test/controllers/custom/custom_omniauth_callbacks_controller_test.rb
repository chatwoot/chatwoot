# frozen_string_literal: true

require 'test_helper'

class Custom::OmniauthCallbacksControllerTest < ActionDispatch::IntegrationTest
  describe Custom::OmniauthCallbacksController do
    include CustomControllersRoutes

    setup do
      OmniAuth.config.test_mode = true
      OmniAuth.config.mock_auth[:facebook] = OmniAuth::AuthHash.new(
        provider: 'facebook',
        uid: '123545',
        info: {
          name: 'swong',
          email: 'swongsong@yandex.ru'
        }
      )
    end

    test 'yield resource to block on omniauth_success success' do
      @redirect_url = 'http://ng-token-auth.dev/'
      post '/nice_user_auth/facebook',
          params: { auth_origin_url: @redirect_url,
                    omniauth_window_type: 'newWindow' }

      follow_all_redirects!

      assert @controller.omniauth_success_block_called?,
             'omniauth_success failed to yield resource to provided block'
    end
  end
end
