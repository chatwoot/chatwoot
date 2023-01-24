class DeviseOverrides::OmniauthCallbacksController < DeviseTokenAuth::OmniauthCallbacksController
  def omniauth_success
    get_resource_from_auth_hash

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

  def resource_class(mapping = nil)
    User
  end

  def get_resource_from_auth_hash
    # find the user with their email instead of UID and token
    @resource = resource_class.where(
      email: auth_hash['info']['email']
    ).first

    if @resource.nil?
      # raise invalid login error instead of user not found
      # this is to prevent enumeration attacks
      raise StandardError, 'Invalid Login'
    end

    # if @resource.nil?
    #   # if this is a new record, create an account with the AccountBuilder
    #   @resource, @account = AccountBuilder.new(
    #     account_name: auth_hash['info']['name'],
    #     user_full_name: auth_hash['info']['name'],
    #     email: auth_hash['info']['email'],
    #     locale: I18n.locale,
    #     confirmed: auth_hash['info']['email_verified']
    #   ).perform
    # end

    @resource
  end

  def default_devise_mapping
    'user'
  end
end
