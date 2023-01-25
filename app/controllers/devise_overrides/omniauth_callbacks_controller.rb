class DeviseOverrides::OmniauthCallbacksController < DeviseTokenAuth::OmniauthCallbacksController
  def omniauth_success
    get_resource_from_auth_hash

    if @resource.nil?
      redirect_to "#{ENV.fetch('FRONTEND_URL', nil)}/app/login?error=oauth-no-user"
      return
    end

    if confirmable_enabled?
      # don't send confirmation email!!!
      @resource.skip_confirmation!
    end

    # once the resource is found and verified
    # we can just send them to the login page again with the SSO params
    # that will log them in
    encoded_email = ERB::Util.url_encode(@resource.email)
    redirect_to "#{ENV.fetch('FRONTEND_URL', nil)}/app/login?email=#{encoded_email}&sso_auth_token=#{@resource.generate_sso_auth_token}"
  end

  def resource_class(_mapping = nil)
    User
  end

  def get_resource_from_auth_hash
    # find the user with their email instead of UID and token
    @resource = resource_class.where(
      email: auth_hash['info']['email']
    ).first
  end

  def default_devise_mapping
    'user'
  end
end
