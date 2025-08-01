class DeviseOverrides::SessionsController < DeviseTokenAuth::SessionsController
  include ::ShopifySessionVerification
  include Shopify::IntegrationHelper

  # Prevent session parameter from being passed
  # Unpermitted parameter: session
  wrap_parameters format: []
  before_action :process_sso_auth_token, only: [:create]

  def new
    redirect_to login_page_url(error: 'access-denied')
  end

  def create    
    shopify_request = false
    # If this is a Shopify installation request, verify HMAC
    if params[:shop].present? && params[:hmac].present? && params[:timestamp].present?
      Rails.logger.info('[Shopify Auth] Verifying HMAC for Shopify installation login')
      
      # Get all parameters (POST body parameters for login)
      query_params = params.to_unsafe_h
      
      # Verify the HMAC signature
      unless verify_shopify_installation_hmac(query_params, params[:hmac])
        Rails.logger.error("[Shopify Auth] Invalid HMAC for shop: #{params[:shop]}")
        return render json: { error: 'Invalid Shopify HMAC signature' }, status: :unauthorized
      end
      
      shopify_request = true
      Rails.logger.info("[Shopify Auth] HMAC verification successful for shop: #{params[:shop]}")
    end
    
    # Authenticate user via the temporary sso auth token
    if params[:sso_auth_token].present? && @resource.present?
      authenticate_resource_with_sso_token
      yield @resource if block_given?
      render_create_success
    else
      super
    end
    
    # After successful authentication, create Shopify inbox if needed
    if @resource && shopify_request
      # check if the shopify domain is already registered
      if !Dashassist::ShopifyStore.find_by(shop: params[:shop]).present?
        Rails.logger.info("[Shopify Auth] Shopify domain #{params[:shop]} is not registered")
        ShopifyInboxCreatorService.new(@resource, params[:shop]).setup_shopify_integration_account_and_inbox
      end
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
    @token = @resource.create_token
    @resource.save!

    sign_in(:user, @resource, store: false, bypass: false)
    # invalidate the token after the user is signed in
    @resource.invalidate_sso_auth_token(params[:sso_auth_token])
  end

  def process_sso_auth_token
    return if params[:email].blank?

    user = User.from_email(params[:email])
    @resource = user if user&.valid_sso_auth_token?(params[:sso_auth_token])
  end
end

DeviseOverrides::SessionsController.prepend_mod_with('DeviseOverrides::SessionsController')
