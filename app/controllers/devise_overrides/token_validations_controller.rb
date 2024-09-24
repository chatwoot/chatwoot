class DeviseOverrides::TokenValidationsController < DeviseTokenAuth::TokenValidationsController
  include BspdAccessHelper

  def validate_token
    # @resource will have been set by set_user_by_token concern
    if @resource
      active_account_id = @resource.active_account_user&.account_id
      Rails.logger.info "User #{@resource.id} signed in. Active Account ID: #{active_account_id}"
      if billing_status(active_account_id)
        render 'devise/token', formats: [:json]
      else
        # log out the user
        sign_out @resource
        render_validate_token_error
      end
    else
      render_validate_token_error
    end
  end
end
