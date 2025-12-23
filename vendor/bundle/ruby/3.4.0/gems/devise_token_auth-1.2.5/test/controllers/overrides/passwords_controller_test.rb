# frozen_string_literal: true

require 'test_helper'

#  was the web request successful?
#  was the user redirected to the right page?
#  was the user successfully authenticated?
#  was the correct object stored in the response?
#  was the appropriate message delivered in the json payload?

class Overrides::PasswordsControllerTest < ActionDispatch::IntegrationTest
  include OverridesControllersRoutes

  describe Overrides::PasswordsController do
    before do
      @resource = create(:user, :confirmed)

      post '/evil_user_auth/password',
           params: {
             email: @resource.email,
             redirect_url: Faker::Internet.url
           }

      mail = ActionMailer::Base.deliveries.last
      @resource.reload

      mail_reset_token  = mail.body.match(/reset_password_token=(.*)\"/)[1]
      mail_redirect_url = CGI.unescape(mail.body.match(/redirect_url=([^&]*)&/)[1])

      get '/evil_user_auth/password/edit',
          params: {
            reset_password_token: mail_reset_token,
            redirect_url: mail_redirect_url
          }

      @resource.reload

      _, raw_query_string = response.location.split('?')
      @query_string = Rack::Utils.parse_nested_query(raw_query_string)
    end

    test 'response should have success redirect status' do
      assert_equal 302, response.status
    end

    test 'response should contain auth params + override proof' do
      assert @query_string['access-token']
      assert @query_string['client']
      assert @query_string['client_id']
      assert @query_string['expiry']
      assert @query_string['override_proof']
      assert @query_string['reset_password']
      assert @query_string['token']
      assert @query_string['uid']
    end

    test 'override proof is correct' do
      assert_equal(
        @query_string['override_proof'],
        Overrides::PasswordsController::OVERRIDE_PROOF
      )
    end
  end
end
