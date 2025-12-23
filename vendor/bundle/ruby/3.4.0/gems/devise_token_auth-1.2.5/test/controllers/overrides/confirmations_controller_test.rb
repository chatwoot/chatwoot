# frozen_string_literal: true

require 'test_helper'

#  was the web request successful?
#  was the user redirected to the right page?
#  was the user successfully authenticated?
#  was the correct object stored in the response?
#  was the appropriate message delivered in the json payload?

class Overrides::ConfirmationsControllerTest < ActionDispatch::IntegrationTest
  include OverridesControllersRoutes

  describe Overrides::ConfirmationsController do
    before do
      @redirect_url = Faker::Internet.url
      @new_user = create(:user)

      # generate + send email
      @new_user.send_confirmation_instructions(redirect_url: @redirect_url)

      @mail = ActionMailer::Base.deliveries.last
      @confirmation_path = @mail.body.match(/localhost([^\"]*)\"/)[1]

      # visit confirmation link
      get @confirmation_path

      # reload user from db
      @new_user.reload
    end

    test 'user is confirmed' do
      assert @new_user.confirmed?
    end

    test 'user can be authenticated via confirmation link' do
      # hard coded in override controller
      override_proof_str = '(^^,)'

      # ensure present in redirect URL
      override_proof_param = CGI.unescape(response.headers['Location']
                                .match(/override_proof=([^&]*)&/)[1])

      assert_equal override_proof_str, override_proof_param
    end
  end
end
