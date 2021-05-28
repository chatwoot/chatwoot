class Api::V1::ProfilesController < Api::BaseController
  before_action :set_user

  def show
    render partial: 'api/v1/models/user.json.jbuilder', locals: { resource: @user }
  end

  def update
    if password_params[:password].present?
      render_could_not_create_error('Invalid current password') and return unless @user.valid_password?(password_params[:current_password])

      @user.update!(password_params.except(:current_password))
    end

    @user.update!(profile_params)
  end

  private

  def set_user
    @user = current_user
  end

  def profile_params
    params.require(:profile).permit(
      :email,
      :name,
      :display_name,
      :avatar,
      :availability,
      ui_settings: {}
    )
  end

  def password_params
    params.require(:profile).permit(
      :current_password,
      :password,
      :password_confirmation
    )
  end
end
