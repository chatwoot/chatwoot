class DeviseOverrides::TokenValidationsController < DeviseTokenAuth::TokenValidationsController
  include ClearSiteData

  def validate_token
    # @resource will have been set by set_user_by_token concern
    if @resource
      render 'devise/token', formats: [:json]
    else
      clear_site_data if request.headers['access-token'].present?
      render_validate_token_error
    end
  end
end
