class Platform::Api::V1::UsersController < PlatformController
  def create
    @resource = User.new(user_params)
    @resource.save!
    render json: @resource
  end

  def show
    render json: @resource
  end

  def update
    @resource.update!(user_params)
    render json: @resource
  end

  def destroy
    # obfusicate user
    head :ok
  end

  private

  def set_resource
    @resource = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:name, :email, :password)
  end
end
