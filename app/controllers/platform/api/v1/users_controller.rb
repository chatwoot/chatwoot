class Platform::Api::V1::UsersController < PlatformController
  # ref: https://stackoverflow.com/a/45190318/939299
  # set resource is called for other actions already in platform controller
  # we want to add login to that chain as well
  before_action(only: [:login]) { set_resource }
  before_action(only: [:login]) { validate_platform_app_permissible }

  def create
    @resource = (User.find_by(email: user_params[:email]) || User.new(user_params))
    @resource.confirm
    @resource.save!
    @platform_app.platform_app_permissibles.find_or_create_by(permissible: @resource)
    render json: @resource
  end

  def login
    render json: { url: "#{ENV['FRONTEND_URL']}/app/login?email=#{@resource.email}&sso_auth_token=#{@resource.generate_sso_auth_token}" }
  end

  def show
    render json: @resource
  end

  def update
    @resource.update!(user_params)
    render json: @resource
  end

  def destroy
    # TODO: obfusicate user
    head :ok
  end

  private

  def set_resource
    @resource = User.find(params[:id])
  end

  def user_params
    params.permit(:name, :email, :password)
  end
end
