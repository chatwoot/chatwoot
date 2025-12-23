# frozen_string_literal: true

require 'test_helper'

#  was the web request successful?
#  was the user redirected to the right page?
#  was the user successfully authenticated?
#  was the correct object stored in the response?
#  was the appropriate message delivered in the json payload?

class Overrides::RegistrationsControllerTest < ActionDispatch::IntegrationTest
  include OverridesControllersRoutes

  describe Overrides::RegistrationsController do
    describe 'Succesful Registration update' do
      before do
        @existing_user  = create(:user, :confirmed)
        @auth_headers   = @existing_user.create_new_auth_token
        @client_id      = @auth_headers['client']
        @favorite_color = 'pink'

        # ensure request is not treated as batch request
        age_token(@existing_user, @client_id)

        # test valid update param
        @new_operating_thetan = 1_000_000

        put '/evil_user_auth',
            params: { favorite_color: @favorite_color },
            headers: @auth_headers

        @data = JSON.parse(response.body)
        @existing_user.reload
      end

      test 'user was updated' do
        assert_equal @favorite_color, @existing_user.favorite_color
      end

      test 'controller was overridden' do
        assert_equal Overrides::RegistrationsController::OVERRIDE_PROOF,
                     @data['override_proof']
      end
    end
  end
end
