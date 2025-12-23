# frozen_string_literal: true

require 'test_helper'

#  was the web request successful?
#  was the user redirected to the right page?
#  was the user successfully authenticated?
#  was the correct object stored in the response?
#  was the appropriate message delivered in the json payload?

class Overrides::TokenValidationsControllerTest < ActionDispatch::IntegrationTest
  include OverridesControllersRoutes

  describe Overrides::TokenValidationsController do
    before do
      @resource = create(:user, :confirmed)

      @auth_headers = @resource.create_new_auth_token

      @token     = @auth_headers['access-token']
      @client_id = @auth_headers['client']
      @expiry    = @auth_headers['expiry']

      # ensure that request is not treated as batch request
      age_token(@resource, @client_id)

      get '/evil_user_auth/validate_token',
          params: {},
          headers: @auth_headers

      @resp = JSON.parse(response.body)
    end

    test 'token valid' do
      assert_equal 200, response.status
    end

    test 'controller was overridden' do
      assert_equal Overrides::TokenValidationsController::OVERRIDE_PROOF,
                   @resp['override_proof']
    end
  end
end
