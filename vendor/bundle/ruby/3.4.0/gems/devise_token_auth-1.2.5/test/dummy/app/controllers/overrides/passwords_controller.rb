# frozen_string_literal: true

module Overrides
  class PasswordsController < DeviseTokenAuth::PasswordsController
    OVERRIDE_PROOF = '(^^,)'.freeze

    # this is where users arrive after visiting the email confirmation link
    def edit
      @resource = resource_class.reset_password_by_token(
        reset_password_token: resource_params[:reset_password_token]
      )

      if @resource && @resource.id
        token = @resource.create_token

        # ensure that user is confirmed
        @resource.skip_confirmation! unless @resource.confirmed_at

        @resource.save!

        redirect_header_options = {
          override_proof: OVERRIDE_PROOF,
          reset_password: true
        }
        redirect_headers = build_redirect_headers(token.token,
                                                  token.client,
                                                  redirect_header_options)
        redirect_to(@resource.build_auth_url(params[:redirect_url],
                                             redirect_headers),
                                             redirect_options)
      else
        raise ActionController::RoutingError, 'Not Found'
      end
    end
  end
end
