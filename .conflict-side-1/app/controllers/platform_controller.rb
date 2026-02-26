class PlatformController < ActionController::API
  include RequestExceptionHandler

  before_action :ensure_access_token
  before_action :set_platform_app
  before_action :set_resource, only: [:update, :show, :destroy]
  before_action :validate_platform_app_permissible, only: [:update, :show, :destroy]

  def show; end

  def update; end

  def destroy; end

  private

  def ensure_access_token
    token = request.headers[:api_access_token] || request.headers[:HTTP_API_ACCESS_TOKEN]
    @access_token = AccessToken.find_by(token: token) if token.present?
  end

  def set_platform_app
    @platform_app = @access_token.owner if @access_token && @access_token.owner.is_a?(PlatformApp)
    render json: { error: 'Invalid access_token' }, status: :unauthorized if @platform_app.blank?
  end

  def set_resource
    # set @resource in your controller
    raise 'Overwrite this method your controller'
  end

  def validate_platform_app_permissible
    return if @platform_app.platform_app_permissibles.find_by(permissible: @resource)

    render json: { error: 'Non permissible resource' }, status: :unauthorized
  end
end
