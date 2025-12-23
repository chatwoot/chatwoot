# frozen_string_literal: true

require 'test_helper'

#  was the web request successful?
#  was the user redirected to the right page?
#  was the user successfully authenticated?
#  was the correct object stored in the response?
#  was the appropriate message delivered in the json payload?

class DemoUserControllerTest < ActionDispatch::IntegrationTest
  include Warden::Test::Helpers
  describe DemoUserController do
    describe 'Token access' do
      before do
        @resource = create(:user, :confirmed)

        @auth_headers = @resource.create_new_auth_token

        @token     = @auth_headers['access-token']
        @client_id = @auth_headers['client']
        @expiry    = @auth_headers['expiry']
      end

      describe 'successful request' do
        before do
          # ensure that request is not treated as batch request
          age_token(@resource, @client_id)

          get '/demo/members_only',
              params: {},
              headers: @auth_headers

          @resp_token       = response.headers['access-token']
          @resp_client_id   = response.headers['client']
          @resp_expiry      = response.headers['expiry']
          @resp_uid         = response.headers['uid']
        end

        describe 'devise mappings' do
          it 'should define current_user' do
            assert_equal @resource, @controller.current_user
          end

          it 'should define user_signed_in?' do
            assert @controller.user_signed_in?
          end

          it 'should not define current_mang' do
            refute_equal @resource, @controller.current_mang
          end

          it 'should define render_authenticate_error' do
            assert @controller.methods.include?(:render_authenticate_error)
          end
        end

        it 'should return success status' do
          assert_equal 200, response.status
        end

        it 'should receive new token after successful request' do
          refute_equal @token, @resp_token
        end

        it 'should preserve the client id from the first request' do
          assert_equal @client_id, @resp_client_id
        end

        it "should return the user's uid in the auth header" do
          assert_equal @resource.uid, @resp_uid
        end

        it 'should not treat this request as a batch request' do
          refute assigns(:is_batch_request)
        end

        describe 'subsequent requests' do
          before do
            @resource.reload
            # ensure that request is not treated as batch request
            age_token(@resource, @client_id)

            get '/demo/members_only',
                params: {},
                headers: @auth_headers.merge('access-token' => @resp_token)
          end

          it 'should not treat this request as a batch request' do
            refute assigns(:is_batch_request)
          end

          it 'should allow a new request to be made using new token' do
            assert_equal 200, response.status
          end
        end
      end

      describe 'failed request' do
        before do
          get '/demo/members_only',
              params: {},
              headers: @auth_headers.merge('access-token' => 'bogus')
        end

        it 'should not return any auth headers' do
          refute response.headers['access-token']
        end

        it 'should return error: unauthorized status' do
          assert_equal 401, response.status
        end
      end

      describe 'disable change_headers_on_each_request' do
        before do
          DeviseTokenAuth.change_headers_on_each_request = false
          @resource.reload
          age_token(@resource, @client_id)

          get '/demo/members_only',
              params: {},
              headers: @auth_headers

          @first_is_batch_request = assigns(:is_batch_request)
          @first_user = assigns(:resource).dup
          @first_access_token = response.headers['access-token']
          @first_response_status = response.status

          @resource.reload
          age_token(@resource, @client_id)

          # use expired auth header
          get '/demo/members_only',
              params: {},
              headers: @auth_headers

          @second_is_batch_request = assigns(:is_batch_request)
          @second_user = assigns(:resource).dup
          @second_access_token = response.headers['access-token']
          @second_response_status = response.status
        end

        after do
          DeviseTokenAuth.change_headers_on_each_request = true
        end

        it 'should allow the first request through' do
          assert_equal 200, @first_response_status
        end

        it 'should allow the second request through' do
          assert_equal 200, @second_response_status
        end

        it 'should return auth headers from the first request' do
          assert @first_access_token
        end

        it 'should not treat either requests as batch requests' do
          refute @first_is_batch_request
          refute @second_is_batch_request
        end

        it 'should return auth headers from the second request' do
          assert @second_access_token
        end

        it 'should define user during first request' do
          assert @first_user
        end

        it 'should define user during second request' do
          assert @second_user
        end
      end

      describe 'batch requests' do
        describe 'success' do
          before do
            age_token(@resource, @client_id)
            # request.headers.merge!(@auth_headers)

            get '/demo/members_only',
                params: {},
                headers: @auth_headers

            @first_is_batch_request = assigns(:is_batch_request)
            @first_user = assigns(:resource)
            @first_access_token = response.headers['access-token']

            get '/demo/members_only',
                params: {},
                headers: @auth_headers

            @second_is_batch_request = assigns(:is_batch_request)
            @second_user = assigns(:resource)
            @second_access_token = response.headers['access-token']
          end

          it 'should allow both requests through' do
            assert_equal 200, response.status
          end

          it 'should not treat the first request as a batch request' do
            refute @first_is_batch_request
          end

          it 'should treat the second request as a batch request' do
            assert @second_is_batch_request
          end

          it 'should return access token for first (non-batch) request' do
            assert @first_access_token
          end

          it 'should not return auth headers for second (batched) requests' do
            assert_equal ' ', @second_access_token
          end
        end

        describe 'unbatch' do
          before do
            @resource.reload
            age_token(@resource, @client_id)

            get '/demo/members_only',
                params: {},
                headers: @auth_headers

            @first_is_batch_request = assigns(:is_batch_request)
            @first_user = assigns(:resource).dup
            @first_access_token = response.headers['access-token']
            @first_response_status = response.status

            get '/demo/members_only?unbatch=true',
                params: {},
                headers: @auth_headers

            @second_is_batch_request = assigns(:is_batch_request)
            @second_user = assigns(:resource)
            @second_access_token = response.headers['access-token']
            @second_response_status = response.status
          end

          it 'should NOT treat the second request as a batch request when "unbatch" param is set' do
            refute @second_is_batch_request
          end
        end

        describe 'time out' do
          before do
            @resource.reload
            age_token(@resource, @client_id)

            get '/demo/members_only',
                params: {},
                headers: @auth_headers

            @first_is_batch_request = assigns(:is_batch_request)
            @first_user = assigns(:resource).dup
            @first_access_token = response.headers['access-token']
            @first_response_status = response.status

            @resource.reload
            age_token(@resource, @client_id)

            # use previous auth header
            get '/demo/members_only',
                params: {},
                headers: @auth_headers

            @second_is_batch_request = assigns(:is_batch_request)
            @second_user = assigns(:resource)
            @second_access_token = response.headers['access-token']
            @second_response_status = response.status

            @resource.reload
            age_token(@resource, @client_id)

            # use expired auth headers
            get '/demo/members_only_mang',
                params: {},
                headers: @auth_headers

            @third_is_batch_request = assigns(:is_batch_request)
            @third_user = assigns(:resource)
            @third_access_token = response.headers['access-token']
            @third_response_status = response.status
          end

          it 'should allow the first request through' do
            assert_equal 200, @first_response_status
          end

          it 'should allow the second request through' do
            assert_equal 200, @second_response_status
          end

          it 'should not allow the second request through' do
            assert_equal 401, @third_response_status
          end

          it 'should not treat first request as batch request' do
            refute @first_is_batch_request
          end

          it 'should not treat second request as batch request' do
            refute @second_is_batch_request
          end

          it 'should not treat third request as batch request' do
            refute @third_is_batch_request
          end

          it 'should return auth headers from the first request' do
            assert @first_access_token
          end

          it 'should return auth headers from the second request' do
            assert @second_access_token
          end

          it 'should not return auth headers from the third request' do
            refute @third_access_token
          end

          it 'should define user during first request' do
            assert @first_user
          end

          it 'should define user during second request' do
            assert @second_user
          end

          it 'should not define user during third request' do
            refute @third_user
          end
        end
      end

      describe 'successful password change' do
        before do
          DeviseTokenAuth.remove_tokens_after_password_reset = true

          # adding one more token to simulate another logged in device
          @old_auth_headers = @auth_headers
          @auth_headers = @resource.create_new_auth_token
          age_token(@resource, @client_id)
          assert @resource.tokens.count > 1

          # password changed from new device
          @resource.update(password: 'newsecret123',
                           password_confirmation: 'newsecret123')

          get '/demo/members_only',
              params: {},
              headers: @auth_headers
        end

        after do
          DeviseTokenAuth.remove_tokens_after_password_reset = false
        end

        it 'should have only one token' do
          assert_equal 1, @resource.tokens.count
        end

        it 'new request should be successful' do
          assert 200, response.status
        end

        describe 'another device should not be able to login' do
          it 'should return forbidden status' do
            get '/demo/members_only',
                params: {},
                headers: @old_auth_headers
            assert 401, response.status
          end
        end
      end

      describe 'request including destroy of token' do
        describe 'when change_headers_on_each_request is set to false' do
          before do
            DeviseTokenAuth.change_headers_on_each_request = false
            age_token(@resource, @client_id)

            get '/demo/members_only_remove_token',
                params: {},
                headers: @auth_headers
          end

          after do
            DeviseTokenAuth.change_headers_on_each_request = true
          end

          it 'should not return auth-headers' do
            refute response.headers['access-token']
          end
        end

        describe 'when change_headers_on_each_request is set to true' do
          before do
            age_token(@resource, @client_id)
            get '/demo/members_only_remove_token',
                params: {},
                headers: @auth_headers
          end

          it 'should not return auth-headers' do
            refute response.headers['access-token']
          end
        end
      end

      describe 'when access-token name has been changed' do
        before do
          # ensure that request is not treated as batch request
          DeviseTokenAuth.headers_names[:'access-token'] = 'new-access-token'
          auth_headers_modified = @resource.create_new_auth_token
          client_id = auth_headers_modified['client']
          age_token(@resource, client_id)

          get '/demo/members_only',
              params: {},
              headers: auth_headers_modified
          @resp_token = response.headers['new-access-token']
        end

        it 'should have "new-access-token" header' do
          assert @resp_token.present?
        end

        after do
          DeviseTokenAuth.headers_names[:'access-token'] = 'access-token'
        end
      end

      describe 'maximum concurrent devices per user' do
        before do
          # Set the max_number_of_devices to a lower number
          #  to expedite tests! (Default is 10)
          DeviseTokenAuth.max_number_of_devices = 5
        end

        it 'should limit the maximum number of concurrent devices' do
          # increment the number of devices until the maximum is exceeded
          1.upto(DeviseTokenAuth.max_number_of_devices + 1).each do |n|

            assert_equal(
              [n, DeviseTokenAuth.max_number_of_devices].min,
              @resource.reload.tokens.length
            )

            # Add a new device (and token) ahead of the next iteration
            @resource.create_new_auth_token

          end
        end

        it 'should drop the oldest token when the maximum number of devices is exceeded' do
          # create the maximum number of tokens
          1.upto(DeviseTokenAuth.max_number_of_devices).each do
            @resource.create_new_auth_token
          end

          # get the oldest token client_id
          oldest_client_id, = @resource.reload.tokens.min_by do |cid, v|
            v[:expiry] || v['expiry']
          end # => [ 'CLIENT_ID', {token: ...} ]

          # create another token, thereby dropping the oldest token
          @resource.create_new_auth_token

          assert_not_includes @resource.reload.tokens.keys, oldest_client_id
        end

        after do
          DeviseTokenAuth.max_number_of_devices = 10
        end
      end
    end

    describe 'bypass_sign_in' do
      before do
        @resource = create(:user)

        @auth_headers = @resource.create_new_auth_token

        @token     = @auth_headers['access-token']
        @client_id = @auth_headers['client']
        @expiry    = @auth_headers['expiry']
      end
      describe 'is default value (true)' do
        before do
          age_token(@resource, @client_id)

          get '/demo/members_only', params: {}, headers: @auth_headers

          @access_token = response.headers['access-token']
          @response_status = response.status
        end

        it 'should allow the request through' do
          assert_equal 200, @response_status
        end

        it 'should return auth headers' do
          assert @access_token
        end

        it 'should set current user' do
          assert_equal @controller.current_user, @resource
        end
      end
      describe 'is false' do
        before do
          DeviseTokenAuth.bypass_sign_in = false
          age_token(@resource, @client_id)

          get '/demo/members_only', params: {}, headers: @auth_headers

          @access_token = response.headers['access-token']
          @response_status = response.status

          DeviseTokenAuth.bypass_sign_in = true
        end

        it 'should not allow the request through' do
          refute_equal 200, @response_status
        end

        it 'should not return auth headers from the first request' do
          assert_nil @access_token
        end
      end
    end

    describe 'enable_standard_devise_support' do
      before do
        @resource = create(:user, :confirmed)
        @auth_headers = @resource.create_new_auth_token
        DeviseTokenAuth.enable_standard_devise_support = true
      end

      describe 'Existing Warden authentication' do
        before do
          @resource = create(:user, :confirmed)
          login_as(@resource, scope: :user)

          # no auth headers sent, testing that warden authenticates correctly.
          get '/demo/members_only',
              params: {},
              headers: nil

          @resp_token       = response.headers['access-token']
          @resp_client_id   = response.headers['client']
          @resp_expiry      = response.headers['expiry']
          @resp_uid         = response.headers['uid']
        end

        describe 'devise mappings' do
          it 'should define current_user' do
            assert_equal @resource, @controller.current_user
          end

          it 'should define user_signed_in?' do
            assert @controller.user_signed_in?
          end

          it 'should not define current_mang' do
            refute_equal @resource, @controller.current_mang
          end

        end

        it 'should return success status' do
          assert_equal 200, response.status
        end

        it 'should receive new token after successful request' do
          assert @resp_token
        end

        it 'should set the token expiry in the auth header' do
          assert @resp_expiry
        end

        it 'should return the client id in the auth header' do
          assert @resp_client_id
        end

        it "should return the user's uid in the auth header" do
          assert @resp_uid
        end
      end

      describe 'existing Warden authentication with ignored token data' do
        before do
          @resource = create(:user, :confirmed)
          login_as(@resource, scope: :user)

          get '/demo/members_only',
              params: {},
              headers: @auth_headers

          @resp_token       = response.headers['access-token']
          @resp_client_id   = response.headers['client']
          @resp_expiry      = response.headers['expiry']
          @resp_uid         = response.headers['uid']
        end

        describe 'devise mappings' do
          it 'should define current_user' do
            assert_equal @resource, @controller.current_user
          end

          it 'should define user_signed_in?' do
            assert @controller.user_signed_in?
          end

          it 'should not define current_mang' do
            refute_equal @resource, @controller.current_mang
          end
        end

        it 'should return success status' do
          assert_equal 200, response.status
        end

        it 'should receive new token after successful request' do
          assert @resp_token
        end

        it 'should set the token expiry in the auth header' do
          assert @resp_expiry
        end

        it 'should return the client id in the auth header' do
          assert @resp_client_id
        end

        it "should not use the existing token's client" do
          refute_equal @auth_headers['client'], @resp_client_id
        end

        it "should return the user's uid in the auth header" do
          assert @resp_uid
        end

        it "should not return the token user's uid in the auth header" do
          refute_equal @resp_uid, @auth_headers['uid']
        end
      end
    end
  end
end
