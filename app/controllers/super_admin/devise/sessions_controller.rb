# frozen_string_literal: true

class SuperAdmin::Devise::SessionsController < Devise::SessionsController
  def new
    self.resource = resource_class.new(sign_in_params)
  end

  def create
    return unless valid_credentials?

    sign_in(@super_admin, scope: :super_admin)
    flash.discard
    redirect_to super_admin_users_path
  end

  def destroy
    sign_out
    flash.discard
    redirect_to '/'
  end

  private

  def valid_credentials?
    @super_admin = SuperAdmin.find_by!(email: params[:super_admin][:email])
    @super_admin.valid_password?(params[:super_admin][:password])
  end
end
