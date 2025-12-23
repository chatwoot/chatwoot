# frozen_string_literal: true

require 'test_helper'

class Custom::PasswordsControllerTest < ActionController::TestCase
  describe Custom::PasswordsController do
    include CustomControllersRoutes

    before do
      @resource = create(:user, :confirmed)
      @redirect_url = 'http://ng-token-auth.dev'
    end

    test 'yield resource to block on create success' do
      post :create,
           params: { email:  @resource.email,
                     redirect_url: @redirect_url }

      @mail = ActionMailer::Base.deliveries.last
      @resource.reload

      @mail_config_name  = CGI.unescape(@mail.body.match(/config=([^&]*)&/)[1])
      @mail_redirect_url = CGI.unescape(@mail.body.match(/redirect_url=([^&]*)&/)[1])
      @mail_reset_token  = @mail.body.match(/reset_password_token=(.*)\"/)[1]

      assert @controller.create_block_called?,
             'create failed to yield resource to provided block'
    end

    test 'yield resource to block on edit success' do
      @resource = create(:user)
      @redirect_url = 'http://ng-token-auth.dev'

      post :create,
           params: { email:  @resource.email,
                     redirect_url: @redirect_url },
           xhr: true

      @mail = ActionMailer::Base.deliveries.last
      @resource.reload

      @mail_config_name  = CGI.unescape(@mail.body.match(/config=([^&]*)&/)[1])
      @mail_redirect_url = CGI.unescape(@mail.body.match(/redirect_url=([^&]*)&/)[1])
      @mail_reset_token  = @mail.body.match(/reset_password_token=(.*)\"/)[1]

      get :edit,
          params: { reset_password_token: @mail_reset_token,
                    redirect_url: @mail_redirect_url },
          xhr: true
      @resource.reload
      assert @controller.edit_block_called?,
             'edit failed to yield resource to provided block'
    end

    test 'yield resource to block on update success' do
      @auth_headers = @resource.create_new_auth_token
      request.headers.merge!(@auth_headers)
      @new_password = Faker::Internet.password
      put :update,
          params: { password: @new_password,
                    password_confirmation: @new_password }
      assert @controller.update_block_called?, 'update failed to yield resource to provided block'
    end

    test 'yield resource to block on update success with custom json' do
      @auth_headers = @resource.create_new_auth_token
      request.headers.merge!(@auth_headers)
      @new_password = Faker::Internet.password
      put :update,
          params: { password: @new_password,
                    password_confirmation: @new_password }

      @data = JSON.parse(response.body)

      assert @controller.update_block_called?, 'update failed to yield resource to provided block'
      assert_equal @data['custom'], 'foo'
    end
  end
end
