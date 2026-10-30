class Public::Api::V1::Portals::AccessController < Public::Api::V1::Portals::BaseController
  skip_before_action :ensure_portal_access

  def create
    return redirect_to(return_path) unless portal.password_protected?

    if portal.authenticate(params[:password].to_s)
      grant_portal_access(portal)
      redirect_to return_path
    else
      @invalid_password = true
      render_portal_password(status: :unprocessable_entity)
    end
  end

  private

  def return_path
    home_path = "/hc/#{portal.slug}"
    return_to = params[:return_to].to_s
    return_to.start_with?("#{home_path}/") ? return_to : home_path
  end
end
