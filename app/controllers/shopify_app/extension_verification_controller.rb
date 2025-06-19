# frozen_string_literal: true

module ShopifyApp
  class ExtensionVerificationController < ActionController::Base
    include ShopifyApp::PayloadVerification
    protect_from_forgery with: :null_session
    before_action :verify_request

    private

    def verify_request
      unless hmac_valid?(request.body.read)
        head(:unauthorized)
        ShopifyApp::Logger.debug("Extension verification failed due to invalid HMAC")
      end
    end
  end
end
