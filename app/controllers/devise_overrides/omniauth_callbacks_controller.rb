class DeviseOverrides::OmniauthCallbacksController < DeviseTokenAuth::OmniauthCallbacksController
  def omniauth_success
    get_resource_from_auth_hash

    if @resource.nil?
      # create a new user & account if we cannot find one
      if validate_bussiness_account
        create_account_for_user
      else
        redirect_to "#{ENV.fetch('FRONTEND_URL', nil)}/app/login?error=business-account-only"
        return
      end
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
    puts auth_hash
    @resource = resource_class.where(
      email: auth_hash['info']['email']
    ).first
  end

  def validate_bussiness_account
    # return true if the user is a business account, false if it is a gmail account
    !auth_hash['info']['email'].include?('@gmail.com')
  end

  def create_account_for_user
    @resource, @account = AccountBuilder.new(
      account_name: auth_hash['info']['name'],
      user_full_name: auth_hash['info']['name'],
      email: auth_hash['info']['email'],
      locale: I18n.locale,
      confirmed: auth_hash['info']['email_verified']
    ).perform
  end

  def default_devise_mapping
    'user'
  end
end
