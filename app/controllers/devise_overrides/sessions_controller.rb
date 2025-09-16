class DeviseOverrides::SessionsController < DeviseTokenAuth::SessionsController
  # Prevent session parameter from being passed
  # Unpermitted parameter: session
  wrap_parameters format: []
  before_action :process_sso_auth_token, only: [:create]

  def new
    redirect_to login_page_url(error: 'access-denied')
  end

  def create
    # Authenticate user via the temporary sso auth token
    if params[:sso_auth_token].present? && @resource.present?
      authenticate_resource_with_sso_token
      yield @resource if block_given?
      render_create_success
    else
      super
    end
  end

  def render_create_success
    render partial: 'devise/auth', formats: [:json], locals: { resource: @resource }
  end

  private

  def login_page_url(error: nil)
    frontend_url = ENV.fetch('FRONTEND_URL', nil)

    "#{frontend_url}/app/login?error=#{error}"
  end

  def authenticate_resource_with_sso_token
    # Follow devise_token_auth's expected flow exactly
    create_and_assign_token

    # Use sign_in with bypass: false (the default) to match devise_token_auth behavior
    sign_in(@resource, scope: :user, store: false, bypass: false)

    # Invalidate the SSO token after the user is signed in
    @resource.invalidate_sso_auth_token(params[:sso_auth_token])
  end

  def create_and_assign_token
    if @resource.respond_to?(:with_lock)
      @resource.with_lock do
        @token = @resource.create_token
        @resource.save!
      end
    else
      @token = @resource.create_token
      @resource.save!
    end
  end

  def process_sso_auth_token
    return if params[:email].blank?

    user = User.from_email(params[:email])

    return unless user && params[:sso_auth_token]

    token_valid = user.valid_sso_auth_token?(params[:sso_auth_token])
    @resource = user if token_valid
  end
end

DeviseOverrides::SessionsController.prepend_mod_with('DeviseOverrides::SessionsController')
