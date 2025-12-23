# frozen_string_literal: true

require 'test_helper'

class Custom::TokenValidationsControllerTest < ActionDispatch::IntegrationTest
  describe Custom::TokenValidationsController do
    include CustomControllersRoutes

    before do
      @resource = create(:user, :confirmed)

      @auth_headers = @resource.create_new_auth_token

      @token     = @auth_headers['access-token']
      @client_id = @auth_headers['client']
      @expiry    = @auth_headers['expiry']

      # ensure that request is not treated as batch request
      age_token(@resource, @client_id)
    end

    test 'yield resource to block on validate_token success' do
      get '/nice_user_auth/validate_token',
          params: {},
          headers: @auth_headers
      assert @controller.validate_token_block_called?,
             'validate_token failed to yield resource to provided block'
    end

    test 'yield resource to block on validate_token success with custom json' do
      get '/nice_user_auth/validate_token',
          params: {},
          headers: @auth_headers

      @data = JSON.parse(response.body)

      assert @controller.validate_token_block_called?,
             'validate_token failed to yield resource to provided block'
      assert_equal @data['custom'], 'foo'
    end
  end
end
