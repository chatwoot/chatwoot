# frozen_string_literal: true

require 'test_helper'

#  was the web request successful?
#  was the user redirected to the right page?
#  was the user successfully authenticated?
#  was the correct object stored in the response?
#  was the appropriate message delivered in the json payload?

class DeviseTokenAuth::RegistrationsControllerTest < ActionDispatch::IntegrationTest
  describe DeviseTokenAuth::RegistrationsController do

    def mock_registration_params
      {
        email: Faker::Internet.unique.email,
        password: 'secret123',
        password_confirmation: 'secret123',
        confirm_success_url: Faker::Internet.url,
        unpermitted_param: '(x_x)'
      }
    end

    describe 'Validate non-empty body' do
      before do
        # need to post empty data
        post '/auth', params: {}

        @resource = assigns(:resource)
        @data = JSON.parse(response.body)
      end

      test 'request should fail' do
        assert_equal 422, response.status
      end

      test 'returns error message' do
        assert_not_empty @data['errors']
      end

      test 'return error status' do
        assert_equal 'error', @data['status']
      end

      test 'user should not have been saved' do
        assert @resource.nil?
      end
    end

    describe 'Successful registration' do
      before do
        @mails_sent = ActionMailer::Base.deliveries.count

        post '/auth',
             params: mock_registration_params

        @resource = assigns(:resource)
        @data = JSON.parse(response.body)
        @mail = ActionMailer::Base.deliveries.last
      end

      test 'request should be successful' do
        assert_equal 200, response.status
      end

      test 'user should have been created' do
        assert @resource.id
      end

      test 'user should not be confirmed' do
        assert_nil @resource.confirmed_at
      end

      test 'new user data should be returned as json' do
        assert @data['data']['email']
      end

      test 'new user should receive confirmation email' do
        assert_equal @resource.email, @mail['to'].to_s
      end

      test 'new user password should not be returned' do
        assert_nil @data['data']['password']
      end

      test 'only one email was sent' do
        assert_equal @mails_sent + 1, ActionMailer::Base.deliveries.count
      end
    end

    describe 'using allow_unconfirmed_access_for' do
      before do
        @original_duration = Devise.allow_unconfirmed_access_for
        Devise.allow_unconfirmed_access_for = nil
      end

      test 'auth headers were returned in response' do
        post '/auth', params: mock_registration_params
        assert response.headers['access-token']
        assert response.headers['token-type']
        assert response.headers['client']
        assert response.headers['expiry']
        assert response.headers['uid']
      end

      describe 'using auth cookie' do
        before do
          DeviseTokenAuth.cookie_enabled = true
        end

        test 'auth cookie was returned in response' do
          post '/auth', params: mock_registration_params
          assert response.cookies[DeviseTokenAuth.cookie_name]
        end

        after do
          DeviseTokenAuth.cookie_enabled = false
        end
      end

      after do
        Devise.allow_unconfirmed_access_for = @original_duration
      end
    end

    describe 'using "+" in email' do
      test 'can use + sign in email addresses' do
        @plus_email = 'ak+testing@gmail.com'

        post '/auth',
             params: { email: @plus_email,
                       password: 'secret123',
                       password_confirmation: 'secret123',
                       confirm_success_url: Faker::Internet.url }

        @resource = assigns(:resource)

        assert_equal @plus_email, @resource.email
      end
    end

    describe 'Using redirect_whitelist' do
      before do
        @good_redirect_url = Faker::Internet.url
        @bad_redirect_url = Faker::Internet.url
        DeviseTokenAuth.redirect_whitelist = [@good_redirect_url]
      end

      teardown do
        DeviseTokenAuth.redirect_whitelist = nil
      end

      test 'request to whitelisted redirect should be successful' do
        post '/auth',
             params: { email: Faker::Internet.unique.email,
                       password: 'secret123',
                       password_confirmation: 'secret123',
                       confirm_success_url: @good_redirect_url,
                       unpermitted_param: '(x_x)' }

        assert_equal 200, response.status
      end

      test 'request to non-whitelisted redirect should fail' do
        post '/auth',
             params: { email: Faker::Internet.unique.email,
                       password: 'secret123',
                       password_confirmation: 'secret123',
                       confirm_success_url: @bad_redirect_url,
                       unpermitted_param: '(x_x)' }
        @data = JSON.parse(response.body)

        assert_equal 422, response.status
        assert @data['errors']
        assert_equal @data['errors'],
                     [I18n.t('devise_token_auth.registrations.redirect_url_not_allowed',
                             redirect_url: @bad_redirect_url)]
      end
    end

    describe 'failure if not redirecturl' do
      test 'request should fail if not redirect_url' do
        post '/auth',
             params: { email: Faker::Internet.unique.email,
                       password: 'secret123',
                       password_confirmation: 'secret123',
                       unpermitted_param: '(x_x)' }

        assert_equal 422, response.status
      end

      test 'request to non-whitelisted redirect should fail' do
        post '/auth',
             params: { email: Faker::Internet.unique.email,
                       password: 'secret123',
                       password_confirmation: 'secret123',
                       unpermitted_param: '(x_x)' }
        @data = JSON.parse(response.body)

        assert @data['errors']
        assert_equal @data['errors'], [I18n.t('devise_token_auth.registrations.missing_confirm_success_url')]
      end
    end

    describe 'Using default_confirm_success_url' do
      before do
        @mails_sent = ActionMailer::Base.deliveries.count
        @redirect_url = Faker::Internet.url

        DeviseTokenAuth.default_confirm_success_url = @redirect_url

        assert_difference 'ActionMailer::Base.deliveries.size', 1 do
          post '/auth', params: { email: Faker::Internet.unique.email,
                                  password: 'secret123',
                                  password_confirmation: 'secret123',
                                  unpermitted_param: '(x_x)' }
        end

        @resource = assigns(:resource)
        @data = JSON.parse(response.body)
        @mail = ActionMailer::Base.deliveries.last
        @sent_redirect_url = CGI.unescape(@mail.body.match(/redirect_url=([^&]*)(&|\")/)[1])
      end

      teardown do
        DeviseTokenAuth.default_confirm_success_url = nil
      end

      test 'request should be successful' do
        assert_equal 200, response.status
      end

      test 'email contains the default redirect url' do
        assert_equal @redirect_url, @sent_redirect_url
      end
    end

    describe 'using namespaces' do
      before do
        @mails_sent = ActionMailer::Base.deliveries.count

        post '/api/v1/auth', params: {
          email: Faker::Internet.unique.email,
          password: 'secret123',
          password_confirmation: 'secret123',
          confirm_success_url: Faker::Internet.url,
          unpermitted_param: '(x_x)'
        }

        @resource = assigns(:resource)
        @data = JSON.parse(response.body)
        @mail = ActionMailer::Base.deliveries.last
      end

      test 'request should be successful' do
        assert_equal 200, response.status
      end

      test 'user should have been created' do
        assert @resource.id
      end
    end

    describe 'case-insensitive email' do
      before do
        @resource_class = User
        @request_params = {
          email: 'AlternatingCase@example.com',
          password: 'secret123',
          password_confirmation: 'secret123',
          confirm_success_url: Faker::Internet.url
        }
      end

      test 'success should downcase uid if configured' do
        @resource_class.case_insensitive_keys = [:email]
        post '/auth', params: @request_params
        assert_equal 200, response.status
        @data = JSON.parse(response.body)
        assert_equal 'alternatingcase@example.com', @data['data']['uid']
      end

      test 'request should not downcase uid if not configured' do
        @resource_class.case_insensitive_keys = []
        post '/auth', params: @request_params
        assert_equal 200, response.status
        @data = JSON.parse(response.body)
        assert_equal 'AlternatingCase@example.com', @data['data']['uid']
      end
    end

    describe 'Adding extra params' do
      before do
        @redirect_url     = Faker::Internet.url
        @operating_thetan = 2

        post '/auth',
             params: { email: Faker::Internet.unique.email,
                       password: 'secret123',
                       password_confirmation: 'secret123',
                       confirm_success_url: @redirect_url,
                       favorite_color: @fav_color,
                       operating_thetan: @operating_thetan }

        @resource = assigns(:resource)
        @data = JSON.parse(response.body)
        @mail = ActionMailer::Base.deliveries.last

        @mail_reset_token  = @mail.body.match(/confirmation_token=([^&]*)[&"]/)[1]
        @mail_redirect_url = CGI.unescape(@mail.body.match(/redirect_url=(.*)\"/)[1])
        @mail_config_name  = CGI.unescape(@mail.body.match(/config=([^&]*)&/)[1])
      end

      test 'redirect_url is included as param in email' do
        assert_equal @redirect_url, @mail_redirect_url
      end

      test 'additional sign_up params should be considered' do
        assert_equal @operating_thetan, @resource.operating_thetan
      end

      test 'config_name param is included in the confirmation email link' do
        assert @mail_config_name
      end

      test "client config name falls back to 'default'" do
        assert_equal 'default', @mail_config_name
      end
    end

    describe 'bad email' do
      before do
        post '/auth',
             params: { email: 'false_email@',
                       password: 'secret123',
                       password_confirmation: 'secret123',
                       confirm_success_url: Faker::Internet.url }

        @resource = assigns(:resource)
        @data = JSON.parse(response.body)
      end

      test 'request should not be successful' do
        assert_equal 422, response.status
      end

      test 'user should not have been created' do
        refute @resource.persisted?
      end

      test 'error should be returned in the response' do
        assert @data['errors'].length
      end

      test 'full_messages should be included in error hash' do
        assert @data['errors']['full_messages'].length
      end
    end

    describe 'missing email' do
      before do
        post '/auth',
             params: { password: 'secret123',
                       password_confirmation: 'secret123',
                       confirm_success_url: Faker::Internet.url }

        @resource = assigns(:resource)
        @data = JSON.parse(response.body)
      end

      test 'request should not be successful' do
        assert_equal 422, response.status
      end

      test 'user should not have been created' do
        refute @resource.persisted?
      end

      test 'error should be returned in the response' do
        assert @data['errors'].length
      end

      test 'full_messages should be included in error hash' do
        assert @data['errors']['full_messages'].length
      end
    end

    describe 'Mismatched passwords' do
      before do
        post '/auth',
             params: { email: Faker::Internet.unique.email,
                       password: 'secret123',
                       password_confirmation: 'bogus',
                       confirm_success_url: Faker::Internet.url }

        @resource = assigns(:resource)
        @data = JSON.parse(response.body)
      end

      test 'request should not be successful' do
        assert_equal 422, response.status
      end

      test 'user should have been created' do
        refute @resource.persisted?
      end

      test 'error should be returned in the response' do
        assert @data['errors'].length
      end

      test 'full_messages should be included in error hash' do
        assert @data['errors']['full_messages'].length
      end
    end

    describe 'Existing users' do
      before do
        @existing_user = create(:user, :confirmed)

        post '/auth',
             params: { email: @existing_user.email,
                       password: 'secret123',
                       password_confirmation: 'secret123',
                       confirm_success_url: Faker::Internet.url }

        @resource = assigns(:resource)
        @data = JSON.parse(response.body)
      end

      test 'request should not be successful' do
        assert_equal 422, response.status
      end

      test 'user should have been created' do
        refute @resource.persisted?
      end

      test 'error should be returned in the response' do
        assert @data['errors'].length
      end
    end

    describe 'Destroy user account' do
      describe 'success' do
        before do
          @existing_user = create(:user, :confirmed)
          @auth_headers  = @existing_user.create_new_auth_token
          @client_id     = @auth_headers['client']

          # ensure request is not treated as batch request
          age_token(@existing_user, @client_id)

          delete '/auth', params: {}, headers: @auth_headers

          @data = JSON.parse(response.body)
        end

        test 'request is successful' do
          assert_equal 200, response.status
        end

        test 'message should be returned' do
          assert @data['message']
          assert_equal @data['message'],
                       I18n.t('devise_token_auth.registrations.account_with_uid_destroyed',
                              uid: @existing_user.uid)
        end
        test 'existing user should be deleted' do
          refute User.where(id: @existing_user.id).first
        end
      end

      describe 'failure: no auth headers' do
        before do
          delete '/auth'
          @data = JSON.parse(response.body)
        end

        test 'request returns 404 (not found) status' do
          assert_equal 404, response.status
        end

        test 'error should be returned' do
          assert @data['errors'].length
          assert_equal @data['errors'], [I18n.t('devise_token_auth.registrations.account_to_destroy_not_found')]
        end
      end
    end

    describe 'Update user account' do
      describe 'existing user' do
        before do
          @existing_user = create(:user, :confirmed)
          @auth_headers  = @existing_user.create_new_auth_token
          @client_id     = @auth_headers['client']

          # ensure request is not treated as batch request
          age_token(@existing_user, @client_id)
        end

        describe 'without password check' do
          describe 'success' do
            before do
              # test valid update param
              @resource_class = User
              @new_operating_thetan = 1_000_000
              @email = Faker::Internet.unique.email
              @request_params = {
                operating_thetan: @new_operating_thetan,
                email: @email
              }
            end

            test 'Request was successful' do
              put '/auth', params: @request_params, headers: @auth_headers
              assert_equal 200, response.status
            end

            test 'Case sensitive attributes update' do
              @resource_class.case_insensitive_keys = []
              put '/auth', params: @request_params, headers: @auth_headers
              @data = JSON.parse(response.body)
              @existing_user.reload
              assert_equal @new_operating_thetan,
                           @existing_user.operating_thetan
              assert_equal @email, @existing_user.email
              assert_equal @email, @existing_user.uid
            end

            test 'Case insensitive attributes update' do
              @resource_class.case_insensitive_keys = [:email]
              put '/auth', params: @request_params, headers: @auth_headers
              @data = JSON.parse(response.body)
              @existing_user.reload
              assert_equal @new_operating_thetan, @existing_user.operating_thetan
              assert_equal @email.downcase, @existing_user.email
              assert_equal @email.downcase, @existing_user.uid
            end

            test 'Supply current password' do
              @request_params[:current_password] = @existing_user.password
              @request_params[:email] = @existing_user.email

              put '/auth', params: @request_params, headers: @auth_headers
              @data = JSON.parse(response.body)
              @existing_user.reload
              assert_equal @existing_user.email, @request_params[:email]
            end
          end

          describe 'validate non-empty body' do
            before do
              # get the email so we can check it wasn't updated
              @email = @existing_user.email
              put '/auth', params: {}, headers: @auth_headers

              @data = JSON.parse(response.body)
              @existing_user.reload
            end

            test 'request should fail' do
              assert_equal 422, response.status
            end

            test 'returns error message' do
              assert_not_empty @data['errors']
            end

            test 'return error status' do
              assert_equal 'error', @data['status']
            end

            test 'user should not have been saved' do
              assert_equal @email, @existing_user.email
            end
          end

          describe 'error' do
            before do
              # test invalid update param
              @new_operating_thetan = 'blegh'
              put '/auth',
                  params: { operating_thetan: @new_operating_thetan },
                  headers: @auth_headers

              @data = JSON.parse(response.body)
              @existing_user.reload
            end

            test 'Request was NOT successful' do
              assert_equal 422, response.status
            end

            test 'Errors were provided with response' do
              assert @data['errors'].length
            end
          end
        end

        describe 'with password check for password update only' do
          before do
            DeviseTokenAuth.check_current_password_before_update = :password
          end

          after do
            DeviseTokenAuth.check_current_password_before_update = false
          end

          describe 'success without password update' do
            before do
              # test valid update param
              @resource_class = User
              @new_operating_thetan = 1_000_000
              @email = Faker::Internet.unique.email
              @request_params = {
                operating_thetan: @new_operating_thetan,
                email: @email
              }
            end

            test 'Request was successful' do
              put '/auth', params: @request_params, headers: @auth_headers
              assert_equal 200, response.status
            end
          end

          describe 'success with password update' do
            before do
              @existing_user.update password: 'secret123', password_confirmation: 'secret123'
              @request_params = {
                password: 'the_new_secret456',
                password_confirmation: 'the_new_secret456',
                current_password: 'secret123'
              }
            end

            test 'Request was successful' do
              put '/auth', params: @request_params, headers: @auth_headers
              assert_equal 200, response.status
            end
          end

          describe 'error with password mismatch' do
            before do
              @existing_user.update password: 'secret123',
                                    password_confirmation: 'secret123'
              @request_params = {
                password: 'the_new_secret456',
                password_confirmation: 'the_new_secret456',
                current_password: 'not_so_secret321'
              }
            end

            test 'Request was NOT successful' do
              put '/auth', params: @request_params, headers: @auth_headers
              assert_equal 422, response.status
            end
          end
        end

        describe 'with password check for all attributes' do
          before do
            DeviseTokenAuth.check_current_password_before_update = :password
            @new_operating_thetan = 1_000_000
            @email = Faker::Internet.unique.email
          end

          after do
            DeviseTokenAuth.check_current_password_before_update = false
          end

          describe 'success with password update' do
            before do
              @existing_user.update password: 'secret123',
                                    password_confirmation: 'secret123'
              @request_params = {
                operating_thetan: @new_operating_thetan,
                email: @email,
                current_password: 'secret123'
              }
            end

            test 'Request was successful' do
              put '/auth', params: @request_params, headers: @auth_headers
              assert_equal 200, response.status
            end
          end

          describe 'error with password mismatch' do
            before do
              @existing_user.update password: 'secret123',
                                    password_confirmation: 'secret123'
              @request_params = {
                operating_thetan: @new_operating_thetan,
                email: @email,
                current_password: 'not_so_secret321'
              }
            end

            test 'Request was NOT successful' do
              put '/auth', params: @request_params, headers: @auth_headers
              assert_equal 422, response.status
            end
          end
        end
      end

      describe 'invalid user' do
        before do
          @existing_user = create(:user, :confirmed)
          @auth_headers  = @existing_user.create_new_auth_token
          @client_id     = @auth_headers['client']

          # ensure request is not treated as batch request
          expire_token(@existing_user, @client_id)

          # test valid update param
          @new_operating_thetan = 3

          put '/auth',
              params: {
                operating_thetan: @new_operating_thetan
              },
              headers: @auth_headers

          @data = JSON.parse(response.body)
          @existing_user.reload
        end

        test 'Response should return 404 status' do
          assert_equal 404, response.status
        end

        test 'error should be returned' do
          assert @data['errors'].length
          assert_equal @data['errors'], [I18n.t('devise_token_auth.registrations.user_not_found')]
        end

        test 'User should not be updated' do
          refute_equal @new_operating_thetan, @existing_user.operating_thetan
        end
      end
    end

    describe 'Ouath user has existing email' do
      before do
        @existing_user = create(:user, :facebook, :confirmed)

        post '/auth',
             params: { email: @existing_user.email,
                       password: 'secret123',
                       password_confirmation: 'secret123',
                       confirm_success_url: Faker::Internet.url }

        @resource = assigns(:resource)
        @data = JSON.parse(response.body)
      end

      test 'request should be successful' do
        assert_equal 200, response.status
      end

      test 'user should have been created' do
        assert @resource.id
      end

      test 'new user data should be returned as json' do
        assert @data['data']['email']
      end
    end

    describe 'Alternate user class' do
      before do
        post '/mangs',
             params: { email: Faker::Internet.unique.email,
                       password: 'secret123',
                       password_confirmation: 'secret123',
                       confirm_success_url: Faker::Internet.url }

        @resource = assigns(:resource)
        @data = JSON.parse(response.body)
        @mail = ActionMailer::Base.deliveries.last
      end

      test 'request should be successful' do
        assert_equal 200, response.status
      end

      test 'use should be a Mang' do
        assert_equal 'Mang', @resource.class.name
      end

      test 'Mang should be destroyed' do
        @resource.skip_confirmation!
        @resource.save!
        @auth_headers  = @resource.create_new_auth_token
        @client_id     = @auth_headers['client']

        # ensure request is not treated as batch request
        age_token(@resource, @client_id)

        delete '/mangs',
               params: {},
               headers: @auth_headers

        assert_equal 200, response.status
        refute Mang.where(id: @resource.id).first
      end
    end

    describe 'Passing client config name' do
      before do
        @config_name = 'altUser'

        post '/mangs',
             params: { email: Faker::Internet.unique.email,
                       password: 'secret123',
                       password_confirmation: 'secret123',
                       confirm_success_url: Faker::Internet.url,
                       config_name: @config_name }

        @resource = assigns(:resource)
        @data = JSON.parse(response.body)
        @mail = ActionMailer::Base.deliveries.last

        @resource.reload

        @mail_reset_token  = @mail.body.match(/confirmation_token=([^&]*)[&"]/)[1]
        @mail_redirect_url = CGI.unescape(@mail.body.match(/redirect_url=(.*)\"/)[1])
        @mail_config_name  = CGI.unescape(@mail.body.match(/config=([^&]*)&/)[1])
      end

      test 'config_name param is included in the confirmation email link' do
        assert_equal @config_name, @mail_config_name
      end
    end

    describe 'Excluded :registrations module' do
      test 'UnregisterableUser should not be able to access registration routes' do
        assert_raises(ActionController::RoutingError) do
          post '/unregisterable_user_auth',
               params: { email: Faker::Internet.unique.email,
                         password: 'secret123',
                         password_confirmation: 'secret123',
                         confirm_success_url: Faker::Internet.url }
        end
      end
    end

    describe 'Skipped confirmation' do
      setup do
        User.set_callback(:create, :before, :skip_confirmation!)

        post '/auth',
             params: { email: Faker::Internet.unique.email,
                       password: 'secret123',
                       password_confirmation: 'secret123',
                       confirm_success_url: Faker::Internet.url }

        @resource  = assigns(:resource)
        @token     = response.headers['access-token']
        @client_id = response.headers['client']
      end

      teardown do
        User.skip_callback(:create, :before, :skip_confirmation!)
      end

      test 'user was created' do
        assert @resource
      end

      test 'user was confirmed' do
        assert @resource.confirmed?
      end

      test 'auth headers were returned in response' do
        assert response.headers['access-token']
        assert response.headers['token-type']
        assert response.headers['client']
        assert response.headers['expiry']
        assert response.headers['uid']
      end

      test 'response token is valid' do
        assert @resource.valid_token?(@token, @client_id)
      end
    end

    describe 'User with only :database_authenticatable and :registerable included' do
      setup do
        @mails_sent = ActionMailer::Base.deliveries.count

        post '/only_email_auth',
             params: { email: Faker::Internet.unique.email,
                       password: 'secret123',
                       password_confirmation: 'secret123',
                       confirm_success_url: Faker::Internet.url,
                       unpermitted_param: '(x_x)' }

        @resource = assigns(:resource)
        @data = JSON.parse(response.body)
        @mail = ActionMailer::Base.deliveries.last
      end

      test 'user was created' do
        assert @resource.id
      end

      test 'email confirmation was not sent' do
        assert_equal @mails_sent, ActionMailer::Base.deliveries.count
      end

      test 'user is confirmed' do
        assert @resource.confirmed?
      end
    end
  end
end
