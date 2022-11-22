class DeviseOverrides::TokenValidationsController < ::DeviseTokenAuth::TokenValidationsController
  def validate_token
    # @resource will have been set by set_user_by_token concern
    if @resource
      render 'devise/token', formats: [:json]
    else
      render_validate_token_error
    end
  end
end
