class Platform::Api::V1::UsersController < PlatformController
  # ref: https://stackoverflow.com/a/45190318/939299
  # set resource is called for other actions already in platform controller
  # we want to add login to that chain as well
  before_action(only: [:login]) { set_resource }
  before_action(only: [:login]) { validate_platform_app_permissible }

  def create
    @resource = (User.find_by(email: user_params[:email]) || User.new(user_params))
    @resource.skip_confirmation!
    @resource.save!
    @platform_app.platform_app_permissibles.find_or_create_by!(permissible: @resource)
  end

  def login
    encoded_email = ERB::Util.url_encode(@resource.email)
    render json: { url: "#{ENV['FRONTEND_URL']}/app/login?email=#{encoded_email}&sso_auth_token=#{@resource.generate_sso_auth_token}" }
  end

  def show; end

  def update
    @resource.assign_attributes(user_update_params)

    # We are using devise's reconfirmable flow for changing emails
    # But in case of platform APIs we don't want user to go through this extra step
    @resource.skip_reconfirmation! if user_update_params[:email].present?
    @resource.save!
  end

  def destroy
    DeleteObjectJob.perform_later(@resource)
    head :ok
  end

  private

  def user_custom_attributes
    return @resource.custom_attributes.merge(user_params[:custom_attributes]) if user_params[:custom_attributes]

    @resource.custom_attributes
  end

  def user_update_params
    # we want the merged custom attributes not the original one
    user_params.except(:custom_attributes).merge({ custom_attributes: user_custom_attributes })
  end

  def set_resource
    @resource = User.find(params[:id])
  end

  def user_params
    params.permit(:name, :email, :password, custom_attributes: {})
  end
end
