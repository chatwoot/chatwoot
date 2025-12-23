# frozen_string_literal: true

require 'test_helper'

#  was the web request successful?
#  was the user redirected to the right page?
#  was the user successfully authenticated?
#  was the correct object stored in the response?
#  was the appropriate message delivered in the json payload?

class Overrides::OmniauthCallbacksControllerTest < ActionDispatch::IntegrationTest
  include OverridesControllersRoutes

  describe Overrides::OmniauthCallbacksController do
    before do
      OmniAuth.config.test_mode = true
      OmniAuth.config.mock_auth[:facebook] = OmniAuth::AuthHash.new(
        provider: 'facebook',
        uid: '123545',
        info: {
          name: 'chong',
          email: 'chongbong@aol.com'
        }
      )

      @favorite_color = 'gray'

      post '/evil_user_auth/facebook',
          params: {
            auth_origin_url: Faker::Internet.url,
            favorite_color: @favorite_color,
            omniauth_window_type: 'newWindow'
          }

      follow_all_redirects!

      @resource = assigns(:resource)
    end

    test 'request is successful' do
      assert_equal 200, response.status
    end

    test 'controller was overridden' do
      assert_equal @resource.nickname,
                   Overrides::OmniauthCallbacksController::DEFAULT_NICKNAME
    end

    test 'whitelisted param was allowed' do
      assert_equal @favorite_color, @resource.favorite_color
    end
  end
end
