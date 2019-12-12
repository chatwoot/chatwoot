class Api::V1::ProfilesController < Api::BaseController
  before_action :fetch_user

  def show
    render json: @user
  end

  def update
    @user.update!(profile_params)
    render json: @user
  end

  private

  def fetch_user
    @user = current_user
  end

  def profile_params
    params.require(:profile).permit(:email, :name, :password, :password_confirmation, :avatar)
  end
end
