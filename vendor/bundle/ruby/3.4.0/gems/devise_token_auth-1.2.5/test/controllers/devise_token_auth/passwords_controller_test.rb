# frozen_string_literal: true

require 'test_helper'

#  was the web request successful?
#  was the user redirected to the right page?
#  was the user successfully authenticated?
#  was the correct object stored in the response?
#  was the appropriate message delivered in the json payload?

class DeviseTokenAuth::PasswordsControllerTest < ActionController::TestCase
  describe DeviseTokenAuth::PasswordsController do
    describe 'Password reset' do
      before do
        @resource = create(:user, :confirmed)
        @redirect_url = 'http://ng-token-auth.dev'
      end

      describe 'not email should return 401' do
        before do
          @auth_headers = @resource.create_new_auth_token
          @new_password = Faker::Internet.password

          post :create,
               params: { redirect_url: @redirect_url }
          @data = JSON.parse(response.body)
        end

        test 'response should fail' do
          assert_equal 401, response.status
        end

        test 'error message should be returned' do
          assert @data['errors']
          assert_equal @data['errors'],
                       [I18n.t('devise_token_auth.passwords.missing_email')]
        end
      end

      describe 'not redirect_url should return 401' do
        before do
          @auth_headers = @resource.create_new_auth_token
          @new_password = Faker::Internet.password
        end

        describe 'for create' do
          before do
            post :create,
                 params: { email: 'chester@cheet.ah' }
            @data = JSON.parse(response.body)
          end

          test 'response should fail' do
            assert_equal 401, response.status
          end

          test 'error message should be returned' do
            assert @data['errors']
            assert_equal(
              @data['errors'],
              [I18n.t('devise_token_auth.passwords.missing_redirect_url')]
            )
          end
        end

        describe 'for edit' do
          before do
            get_reset_token
            get :edit, params: { reset_password_token: @mail_reset_token}
            @data = JSON.parse(response.body)
          end

          test 'response should fail' do
            assert_equal 401, response.status
          end

          test 'error message should be returned' do
            assert @data['errors']
            assert_equal(
              @data['errors'],
              [I18n.t('devise_token_auth.passwords.missing_redirect_url')]
            )
          end
        end
      end

      describe 'request password reset' do
        describe 'unknown user' do
          describe 'without paranoid mode' do
            before do
              post :create,
                   params: { email: 'chester@cheet.ah',
                             redirect_url: @redirect_url }
              @data = JSON.parse(response.body)
            end

            test 'unknown user should return 404' do
              assert_equal 404, response.status
            end

            test 'errors should be returned' do
              assert @data['errors']
              assert_equal @data['errors'],
              [I18n.t('devise_token_auth.passwords.user_not_found',
                      email: 'chester@cheet.ah')]
            end
          end

          describe 'with paranoid mode' do
            before do
              swap Devise, paranoid: true do
                post :create,
                     params: { email: 'chester@cheet.ah',
                               redirect_url: @redirect_url }
                @data = JSON.parse(response.body)
              end
            end

            test 'response should return success status' do
              assert_equal 200, response.status
            end

            test 'response should contain message' do
              assert_equal \
                @data['message'],
              I18n.t('devise_token_auth.passwords.sended_paranoid')
            end
          end
        end

        describe 'successfully requested password reset' do
          describe 'without paranoid mode' do
            before do
              post :create,
                   params: { email: @resource.email,
                             redirect_url: @redirect_url }

              @data = JSON.parse(response.body)
            end

            test 'response should not contain extra data' do
              assert_nil @data['data']
            end

            test 'response should contains message' do
              assert_equal \
                @data['message'],
              I18n.t('devise_token_auth.passwords.sended', email: @resource.email)
            end
          end

          describe 'with paranoid mode' do
            before do
              swap Devise, paranoid: true do
                post :create,
                     params: { email: @resource.email,
                               redirect_url: @redirect_url }
                @data = JSON.parse(response.body)
              end
            end

            test 'response should return success status' do
              assert_equal 200, response.status
            end

            test 'response should contain message' do
              assert_equal \
                @data['message'],
              I18n.t('devise_token_auth.passwords.sended_paranoid')
            end
          end
        end

        describe 'case-sensitive email' do
          before do
            post :create,
                 params: { email: @resource.email,
                           redirect_url: @redirect_url }

            @mail = ActionMailer::Base.deliveries.last
            @resource.reload
            @data = JSON.parse(response.body)

            @mail_config_name  = CGI.unescape(@mail.body.match(/config=([^&]*)&/)[1])
            @mail_redirect_url = CGI.unescape(@mail.body.match(/redirect_url=([^&]*)&/)[1])
            @mail_reset_token  = @mail.body.match(/reset_password_token=(.*)\"/)[1]
          end

          test 'response should return success status' do
            assert_equal 200, response.status
          end

          test 'response should contains message' do
            assert_equal \
              @data['message'],
              I18n.t('devise_token_auth.passwords.sended', email: @resource.email)
          end

          test 'action should send an email' do
            assert @mail
          end

          test 'the email should be addressed to the user' do
            assert_equal @mail.to.first, @resource.email
          end

          test 'the email body should contain a link with redirect url as a query param' do
            assert_equal @redirect_url, @mail_redirect_url
          end

          test 'the client config name should fall back to "default"' do
            assert_equal 'default', @mail_config_name
          end

          test 'the email body should contain a link with reset token as a query param' do
            user = User.reset_password_by_token(reset_password_token: @mail_reset_token)

            assert_equal user.id, @resource.id
          end

          describe 'password reset link failure' do
            test 'response should return 404' do
              assert_raises(ActionController::RoutingError) do
                get :edit,
                    params: { reset_password_token: 'bogus',
                              redirect_url: @mail_redirect_url }
              end
            end
          end

          describe 'password reset link success' do
            before do
              get :edit,
                  params: { reset_password_token: @mail_reset_token,
                            redirect_url: @mail_redirect_url }

              @resource.reload

              raw_qs = response.location.split('?')[1]
              @qs = Rack::Utils.parse_nested_query(raw_qs)

              @access_token   = @qs['access-token']
              @client_id      = @qs['client_id']
              @client         = @qs['client']
              @expiry         = @qs['expiry']
              @reset_password = @qs['reset_password']
              @token          = @qs['token']
              @uid            = @qs['uid']
            end

            test 'response should have success redirect status' do
              assert_equal 302, response.status
            end

            test 'response should contain auth params' do
              assert @access_token
              assert @client
              assert @client_id
              assert @expiry
              assert @reset_password
              assert @token
              assert @uid
            end

            test 'response auth params should be valid' do
              assert @resource.valid_token?(@token, @client_id)
              assert @resource.valid_token?(@access_token, @client)
            end
          end
        end

        describe 'case-insensitive email' do
          before do
            @resource_class = User
            @request_params = {
              email:        @resource.email.upcase,
              redirect_url: @redirect_url
            }
          end

          test 'response should return success status if configured' do
            @resource_class.case_insensitive_keys = [:email]
            post :create, params: @request_params
            assert_equal 200, response.status
          end

          test 'response should return failure status if not configured' do
            @resource_class.case_insensitive_keys = []
            post :create, params: @request_params
            assert_equal 404, response.status
          end
        end

        describe 'Checking reset_password_token' do
          before do
            post :create, params: {
              email: @resource.email,
              redirect_url: @redirect_url
            }

            @mail = ActionMailer::Base.deliveries.last
            @mail_redirect_url = CGI.unescape(@mail.body.match(/redirect_url=([^&]*)&/)[1])
            @mail_reset_token  = @mail.body.match(/reset_password_token=(.*)\"/)[1]

            @resource.reload
          end

          describe 'reset_password_token is valid' do

            test 'mail_reset_token should be the same as reset_password_token' do
              assert_equal Devise.token_generator.digest(self, :reset_password_token, @mail_reset_token), @resource.reset_password_token
            end

            test 'reset_password_token should not be rewritten by origin mail_reset_token' do
              get :edit, params: {
                reset_password_token: @mail_reset_token,
                redirect_url: @mail_redirect_url
              }
              @resource.reload

              assert_equal Devise.token_generator.digest(self, :reset_password_token, @mail_reset_token), @resource.reset_password_token
            end

            test 'response should return success status' do
              get :edit, params: {
                reset_password_token: @mail_reset_token,
                redirect_url: @mail_redirect_url
              }

              assert_equal 302, response.status
            end

            test 'reset_password_sent_at should be valid' do
              assert_equal @resource.reset_password_period_valid?, true

              get :edit, params: {
                reset_password_token: @mail_reset_token,
                redirect_url: @mail_redirect_url
              }

              @resource.reload
              assert_equal Devise.token_generator.digest(self, :reset_password_token, @mail_reset_token), @resource.reset_password_token
            end

            test 'reset_password_sent_at should be expired' do
              assert_equal @resource.reset_password_period_valid?, true

              @resource.update reset_password_sent_at: @resource.reset_password_sent_at - Devise.reset_password_within - 1.seconds
              assert_equal @resource.reset_password_period_valid?, false

              assert_raises(ActionController::RoutingError) {
                get :edit, params: {
                  reset_password_token: @mail_reset_token,
                  redirect_url: @mail_redirect_url
                }
              }
            end
          end

          describe 'reset_password_token is not valid' do
            test 'response should return error status' do
              @resource.update reset_password_token: 'koskoskoskos'

              assert_not_equal Devise.token_generator.digest(self, :reset_password_token, @mail_reset_token), @resource.reset_password_token

              assert_raises(ActionController::RoutingError) {
                get :edit, params: {
                  reset_password_token: @mail_reset_token,
                  redirect_url: @mail_redirect_url
                }
              }
            end
          end
        end
      end

      describe 'Using default_password_reset_url' do
        before do
          @resource = create(:user, :confirmed)
          @redirect_url = 'http://ng-token-auth.dev'

          DeviseTokenAuth.default_password_reset_url = @redirect_url

          post :create,
               params: { email: @resource.email,
                         redirect_url: @redirect_url }

          @mail = ActionMailer::Base.deliveries.last
          @resource.reload

          @sent_redirect_url = CGI.unescape(@mail.body.match(/redirect_url=([^&]*)&/)[1])
        end

        teardown do
          DeviseTokenAuth.default_password_reset_url = nil
        end

        test 'response should return success status' do
          assert_equal 200, response.status
        end

        test 'action should send an email' do
          assert @mail
        end

        test 'the email body should contain a link with redirect url as a query param' do
          assert_equal @redirect_url, @sent_redirect_url
        end
      end

      describe 'Using redirect_whitelist' do
        before do
          @good_redirect_url = @redirect_url
          @bad_redirect_url = Faker::Internet.url
          DeviseTokenAuth.redirect_whitelist = [@good_redirect_url]
        end

        teardown do
          DeviseTokenAuth.redirect_whitelist = nil
        end

        describe 'for create' do
          test 'request to whitelisted redirect should be successful' do
            post :create,
                 params: { email: @resource.email,
                           redirect_url: @good_redirect_url }

            assert_equal 200, response.status
          end

          test 'request to non-whitelisted redirect should fail' do
            post :create,
                 params: { email: @resource.email,
                           redirect_url: @bad_redirect_url }

            assert_equal 422, response.status
          end

          test 'request to non-whitelisted redirect should return error message' do
            post :create,
                 params: { email: @resource.email,
                           redirect_url: @bad_redirect_url }

            @data = JSON.parse(response.body)
            assert @data['errors']
            assert_equal @data['errors'],
                         [I18n.t('devise_token_auth.passwords.not_allowed_redirect_url',
                                 redirect_url: @bad_redirect_url)]
          end
        end

        describe 'for edit' do
          before do
            @auth_headers = @resource.create_new_auth_token
            @new_password = Faker::Internet.password

            get_reset_token
          end

          test 'request to whitelisted redirect should be successful' do
            get :edit, params: { reset_password_token: @mail_reset_token, redirect_url: @good_redirect_url }

            assert_equal 302, response.status
          end

          test 'request to non-whitelisted redirect should fail' do
            get :edit, params: { reset_password_token: @mail_reset_token, redirect_url: @bad_redirect_url }

            assert_equal 422, response.status
          end

          test 'request to non-whitelisted redirect should return error message' do
            get :edit, params: { reset_password_token: @mail_reset_token, redirect_url: @bad_redirect_url }

            @data = JSON.parse(response.body)
            assert @data['errors']
            assert_equal @data['errors'],
                         [I18n.t('devise_token_auth.passwords.not_allowed_redirect_url',
                                 redirect_url: @bad_redirect_url)]
          end
        end
      end

      describe 'change password with current password required' do
        before do
          DeviseTokenAuth.check_current_password_before_update = :password
        end

        after do
          DeviseTokenAuth.check_current_password_before_update = false
        end

        describe 'success' do
          before do
            DeviseTokenAuth.require_client_password_reset_token = false
            @auth_headers = @resource.create_new_auth_token
            request.headers.merge!(@auth_headers)
            @new_password = Faker::Internet.password
            @resource.update password: 'secret123', password_confirmation: 'secret123'

            put :update,
                params: { password: @new_password,
                          password_confirmation: @new_password,
                          current_password: 'secret123' }

            @data = JSON.parse(response.body)
            @resource.reload
          end

          test 'request should be successful' do
            assert_equal 200, response.status
          end
        end

        describe 'success with after password reset' do
          before do
            # create a new password reset request
            post :create, params: { email: @resource.email,
                                    redirect_url: @redirect_url }

            @mail = ActionMailer::Base.deliveries.last
            @mail_redirect_url = CGI.unescape(@mail.body.match(/redirect_url=([^&]*)&/)[1])
            @mail_reset_token  = @mail.body.match(/reset_password_token=(.*)\"/)[1]

            # confirm via password reset email link
            get :edit, params: { reset_password_token: @mail_reset_token,
                                 redirect_url: @mail_redirect_url }

            @resource.reload
            @allow_password_change_after_reset = @resource.allow_password_change

            @auth_headers = @resource.create_new_auth_token
            request.headers.merge!(@auth_headers)
            @new_password = Faker::Internet.password

            put :update, params: { password: @new_password,
                                   password_confirmation: @new_password }

            @data = JSON.parse(response.body)
            @resource.reload
            @allow_password_change = @resource.allow_password_change
            @resource.reload
          end

          test 'request should be successful' do
            assert_equal 200, response.status
          end

          test 'changes allow_password_change to true on reset' do
            assert_equal true, @allow_password_change_after_reset
          end

          test 'sets allow_password_change false' do
            assert_equal false, @allow_password_change
          end
        end

        describe 'current password mismatch error' do
          before do
            DeviseTokenAuth.require_client_password_reset_token = false
            @auth_headers = @resource.create_new_auth_token
            request.headers.merge!(@auth_headers)
            @new_password = Faker::Internet.password

            put :update, params: { password: @new_password,
                                   password_confirmation: @new_password,
                                   current_password: 'not_very_secret321' }
          end

          test 'response should fail unauthorized' do
            assert_equal 422, response.status
          end
        end
      end

      describe 'change password' do
        describe 'using reset token' do
          before do
            DeviseTokenAuth.require_client_password_reset_token = true
            @redirect_url = 'http://client-app.dev'
            get_reset_token
            edit_url = CGI.unescape(@mail.body.match(/href=\"(.+)\"/)[1])
            query_parts = Rack::Utils.parse_nested_query(URI.parse(edit_url).query)
            get :edit, params: query_parts
          end

          test 'request should be redirect' do
            assert_equal 302, response.status
          end

          test 'request should redirect to correct redirect url' do
            host = URI.parse(response.location).host
            query_parts = Rack::Utils.parse_nested_query(URI.parse(response.location).query)

            assert_equal 'client-app.dev', host
            assert_equal @mail_reset_token, query_parts['reset_password_token']
            assert_equal 1, query_parts.keys.size
          end

          teardown do
            DeviseTokenAuth.require_client_password_reset_token = false
          end
        end

        describe 'with valid headers' do
          before do
            @auth_headers = @resource.create_new_auth_token
            request.headers.merge!(@auth_headers)
            @new_password = Faker::Internet.password

            put :update, params: { password: @new_password,
                                   password_confirmation: @new_password }

            @data = JSON.parse(response.body)
            @resource.reload
          end

          test 'request should be successful' do
            assert_equal 200, response.status
          end

          test 'request should return success message' do
            assert @data['message']
            assert_equal @data['message'],
                         I18n.t('devise_token_auth.passwords.successfully_updated')
          end

          test 'new password should authenticate user' do
            assert @resource.valid_password?(@new_password)
          end

          test 'reset_password_token should be removed' do
            assert_nil @resource.reset_password_token
          end
        end

        describe 'password mismatch error' do
          before do
            @auth_headers = @resource.create_new_auth_token
            request.headers.merge!(@auth_headers)
            @new_password = Faker::Internet.password

            put :update, params: { password: 'chong',
                                   password_confirmation: 'bong' }
          end

          test 'response should fail' do
            assert_equal 422, response.status
          end
        end

        describe 'without valid headers' do
          before do
            @resource.create_new_auth_token
            new_password = Faker::Internet.password

            put :update, params: { password: new_password,
                                   password_confirmation: new_password }
          end

          test 'response should fail' do
            assert_equal 401, response.status
          end
        end

        describe 'with valid reset password token' do
          before do
            reset_password_token = @resource.send_reset_password_instructions
            @new_password = Faker::Internet.password
            @params = { password: @new_password,
                        password_confirmation: @new_password,
                        reset_password_token: reset_password_token }
          end

          describe 'with require_client_password_reset_token disabled' do
            before do
              DeviseTokenAuth.require_client_password_reset_token = false
              put :update, params: @params

              @data = JSON.parse(response.body)
              @resource.reload
            end

            test 'request should be not be successful' do
              assert_equal 401, response.status
            end
          end

          describe 'with require_client_password_reset_token enabled' do
            before do
              DeviseTokenAuth.require_client_password_reset_token = true
              put :update, params: @params

              @data = JSON.parse(response.body)
              @resource.reload
            end

            test 'request should be successful' do
              assert_equal 200, response.status
            end

            test 'request should return success message' do
              assert @data['message']
              assert_equal @data['message'],
                           I18n.t('devise_token_auth.passwords.successfully_updated')
            end

            test 'new password should authenticate user' do
              assert @resource.valid_password?(@new_password)
            end

            teardown do
              DeviseTokenAuth.require_client_password_reset_token = false
            end
          end
        end

        describe 'with invalid reset password token' do
          before do
            DeviseTokenAuth.require_client_password_reset_token = true
            @resource.update reset_password_token: 'koskoskoskos'
            put :update, params: @params
            @data = JSON.parse(response.body)
            @resource.reload
          end

          test 'request should fail' do
            assert_equal 401, response.status
          end

          test 'new password should not authenticate user' do
            assert !@resource.valid_password?(@new_password)
          end

          teardown do
            DeviseTokenAuth.require_client_password_reset_token = false
          end
        end
      end
    end

    describe 'Alternate user class' do
      setup do
        @request.env['devise.mapping'] = Devise.mappings[:mang]
      end

      teardown do
        @request.env['devise.mapping'] = Devise.mappings[:user]
      end

      before do
        @resource = create(:mang_user, :confirmed)
        @redirect_url = 'http://ng-token-auth.dev'
        get_reset_token
      end

      test 'response should return success status' do
        assert_equal 200, response.status
      end

      test 'the email body should contain a link with reset token as a query param' do
        user = Mang.reset_password_by_token(reset_password_token: @mail_reset_token)

        assert_equal user.id, @resource.id
      end
    end

    describe 'unconfirmed user' do
      before do
        @resource = create(:user)
        @redirect_url = 'http://ng-token-auth.dev'

        get_reset_token

        get :edit, params: { reset_password_token: @mail_reset_token,
                             redirect_url: @mail_redirect_url }

        @resource.reload
      end
    end

    describe 'unconfirmable user' do
      setup do
        @request.env['devise.mapping'] = Devise.mappings[:unconfirmable_user]
      end

      teardown do
        @request.env['devise.mapping'] = Devise.mappings[:user]
      end

      before do
        @resource = unconfirmable_users(:user)

        get_reset_token

        get :edit, params: { reset_password_token: @mail_reset_token,
                             redirect_url: @mail_redirect_url }

        @resource.reload
      end
    end

    describe 'alternate user type' do
      before do
        @resource = create(:user, :confirmed)
        @redirect_url = 'http://ng-token-auth.dev'
        @config_name  = 'altUser'

        params = { email: @resource.email,
                                redirect_url: @redirect_url,
                                config_name: @config_name }
        get_reset_token params
      end

      test 'config_name param is included in the confirmation email link' do
        assert_equal @config_name, @mail_config_name
      end
    end

    def get_reset_token(params = nil)
      params ||= { email: @resource.email, redirect_url: @redirect_url }
      post :create, params: params

      @mail = ActionMailer::Base.deliveries.last
      @resource.reload

      @mail_config_name  = CGI.unescape(@mail.body.match(/config=([^&]*)&/)[1])
      @mail_redirect_url = CGI.unescape(@mail.body.match(/redirect_url=([^&]*)&/)[1])
      @mail_reset_token  = @mail.body.match(/reset_password_token=(.*)\"/)[1]
    end
  end
end
