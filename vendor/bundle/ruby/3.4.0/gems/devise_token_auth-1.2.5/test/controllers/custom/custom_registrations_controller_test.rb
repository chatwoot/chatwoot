# frozen_string_literal: true

require 'test_helper'

class Custom::RegistrationsControllerTest < ActionDispatch::IntegrationTest
  describe Custom::RegistrationsController do
    include CustomControllersRoutes

    before do
      @create_params = attributes_for(:user,
        confirm_success_url: Faker::Internet.url,
        unpermitted_param: '(x_x)')

      @existing_user = create(:user, :confirmed)
      @auth_headers  = @existing_user.create_new_auth_token
      @client_id     = @auth_headers['client']

      # ensure request is not treated as batch request
      age_token(@existing_user, @client_id)
    end

    test 'yield resource to block on create success' do
      post '/nice_user_auth', params: @create_params
      assert @controller.create_block_called?,
             'create failed to yield resource to provided block'
    end

    test 'yield resource to block on create success with custom json' do
      post '/nice_user_auth', params: @create_params

      @data = JSON.parse(response.body)

      assert @controller.create_block_called?,
             'create failed to yield resource to provided block'
      assert_equal @data['custom'], 'foo'
    end

    test 'yield resource to block on update success' do
      put '/nice_user_auth',
          params: {
            nickname: "Ol' Sunshine-face"
          },
          headers: @auth_headers
      assert @controller.update_block_called?,
             'update failed to yield resource to provided block'
    end

    test 'yield resource to block on destroy success' do
      delete '/nice_user_auth', headers: @auth_headers
      assert @controller.destroy_block_called?,
             'destroy failed to yield resource to provided block'
    end

    describe 'when overriding #build_resource' do
      test 'it fails' do
        Custom::RegistrationsController.any_instance.stubs(:build_resource).returns(nil)
        assert_raises DeviseTokenAuth::Errors::NoResourceDefinedError do
          post '/nice_user_auth', params: @create_params
        end
      end
    end
  end
end
