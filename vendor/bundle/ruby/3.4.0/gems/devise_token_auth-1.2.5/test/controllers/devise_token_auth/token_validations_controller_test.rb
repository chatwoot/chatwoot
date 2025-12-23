# frozen_string_literal: true

require 'test_helper'

#  was the web request successful?
#  was the user redirected to the right page?
#  was the user successfully authenticated?
#  was the correct object stored in the response?
#  was the appropriate message delivered in the json payload?

class DeviseTokenAuth::TokenValidationsControllerTest < ActionDispatch::IntegrationTest
  describe DeviseTokenAuth::TokenValidationsController do
    before do
      @resource = create(:user, :confirmed)

      @auth_headers = @resource.create_new_auth_token

      @token     = @auth_headers['access-token']
      @client_id = @auth_headers['client']
      @expiry    = @auth_headers['expiry']
      @authorization_header = @auth_headers.slice('Authorization')
      # ensure that request is not treated as batch request
      age_token(@resource, @client_id)
    end

    describe 'using only Authorization header' do
      describe 'using valid Authorization header' do
        before do
          get '/auth/validate_token', params: {}, headers: @authorization_header
        end

        test 'token valid' do
          assert_equal 200, response.status
        end
      end

      describe 'using invalid Authorization header' do
        describe 'with invalid base64' do
          before do
            get '/auth/validate_token', params: {}, headers: {'Authorization': 'Bearer invalidtoken=='}
          end

          test 'returns access denied' do
            assert_equal 401, response.status
          end
        end

        describe 'with valid base64' do
          before do
            valid_base64 = Base64.strict_encode64({
              "access-token": 'invalidtoken',
              "token-type": 'Bearer',
              "client": 'client',
              "expiry": '1234567'
            }.to_json)
            get '/auth/validate_token', params: {}, headers: {'Authorization': "Bearer #{valid_base64}"}
          end

          test 'returns access denied' do
            assert_equal 401, response.status
          end
        end
      end
    end

    describe 'vanilla user' do
      before do
        get '/auth/validate_token', params: {}, headers: @auth_headers
        @resp = JSON.parse(response.body)
      end

      test 'token valid' do
        assert_equal 200, response.status
      end
    end

    describe 'using namespaces' do
      before do
        get '/api/v1/auth/validate_token', params: {}, headers: @auth_headers
        @resp = JSON.parse(response.body)
      end

      test 'token valid' do
        assert_equal 200, response.status
      end
    end

    describe 'with invalid user' do
      before do
        @resource.update_column(:email, 'invalid') if DEVISE_TOKEN_AUTH_ORM == :active_record
        @resource.set(email: 'invalid') if DEVISE_TOKEN_AUTH_ORM == :mongoid
      end

      test 'request should raise invalid model error' do
        error = assert_raises DeviseTokenAuth::Errors::InvalidModel do
          get '/auth/validate_token', params: {}, headers: @auth_headers
        end
        assert_equal(error.message, "Cannot set auth token in invalid model. Errors: [\"Email is not an email\"]")
      end
    end

    describe 'failure' do
      before do
        get '/api/v1/auth/validate_token',
            params: {},
            headers: @auth_headers.merge('access-token' => '12345')
        @resp = JSON.parse(response.body)
      end

      test 'request should fail' do
        assert_equal 401, response.status
      end

      test 'response should contain errors' do
        assert @resp['errors']
        assert_equal @resp['errors'], [I18n.t('devise_token_auth.token_validations.invalid')]
      end
    end
  end

  describe 'using namespaces with unused resource' do
    before do
      @resource = create(:scoped_user, :confirmed)

      @auth_headers = @resource.create_new_auth_token

      @token     = @auth_headers['access-token']
      @client_id = @auth_headers['client']
      @expiry    = @auth_headers['expiry']

      # ensure that request is not treated as batch request
      age_token(@resource, @client_id)
    end

    test 'should be successful' do
      get '/api_v2/auth/validate_token',
          params: {},
          headers: @auth_headers
      assert_equal 200, response.status
    end
  end
end
