class Users::OmniauthCallbacksController < DeviseTokenAuth::OmniauthCallbacksController
  def omniauth_success
    get_resource_from_auth_hash

    if confirmable_enabled?
      # don't send confirmation email!!!
      @resource.skip_confirmation!
    end

    @resource.save!
    encoded_email = ERB::Util.url_encode(@resource.email)
    redirect_to "#{ENV.fetch('FRONTEND_URL', nil)}/app/login?email=#{encoded_email}&sso_auth_token=#{@resource.generate_sso_auth_token}"
  end

  def resource_class(mapping = nil)
    User
  end

  def get_resource_from_auth_hash
    # find or create user by provider and provider uid
    @resource = resource_class.where(
      email: auth_hash['info']['email']
    ).first

    if @resource.nil?
      # raise invalid login error instead of user not found
      # this is to prevent enumeration attacks
      raise StandardError, 'Invalid Login'
    end

    @resource
  end

  def default_devise_mapping
    'user'
  end
end
