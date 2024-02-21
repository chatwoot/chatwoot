class Api::V1::ProfilesController < Api::BaseController
  before_action :set_user

  def show; end

  def update
    if password_params[:password].present?
      render_could_not_create_error('Invalid current password') and return unless @user.valid_password?(password_params[:current_password])

      @user.update!(password_params.except(:current_password))
    end

    @user.assign_attributes(profile_params)
    @user.custom_attributes.merge!(custom_attributes_params)
    @user.save!
  end

  def avatar
    @user.avatar.attachment.destroy! if @user.avatar.attached?
    head :ok
  end

  def auto_offline
    @user.account_users.find_by!(account_id: auto_offline_params[:account_id]).update!(auto_offline: auto_offline_params[:auto_offline] || false)
  end

  def availability
    # Log the start of the method
    Rails.logger.debug { 'Starting availability update' }

    # Retrieve the account_id and availability from the parameters
    account_id = availability_params[:account_id]
    new_availability = availability_params[:availability]

    # Log the retrieved parameters
    Rails.logger.debug { "Parameters: account_id: #{account_id}, availability: #{new_availability}" }

    # Find the AccountUser record
    account_user = @user.account_users.find_by(account_id: account_id)

    # Check if the AccountUser record is found
    if account_user
      # Log the current availability of the AccountUser
      Rails.logger.debug { "Current availability of AccountUser (ID: #{account_user.id}): #{account_user.availability}" }

      # Update the availability
      update_result = account_user.update(availability: new_availability)

      # Log the result of the update operation
      Rails.logger.debug { "Update result: #{update_result}" }
    else
      # Log if the AccountUser record is not found
      Rails.logger.debug { "No AccountUser found for user_id: #{@user.id} and account_id: #{account_id}" }
    end
  end

  def set_active_account
    @user.account_users.find_by(account_id: profile_params[:account_id]).update(active_at: Time.now.utc)
    head :ok
  end

  def resend_confirmation
    @user.send_confirmation_instructions unless @user.confirmed?
    head :ok
  end

  private

  def set_user
    @user = current_user
  end

  def availability_params
    params.require(:profile).permit(:account_id, :availability)
  end

  def auto_offline_params
    params.require(:profile).permit(:account_id, :auto_offline)
  end

  def profile_params
    params.require(:profile).permit(
      :email,
      :name,
      :display_name,
      :avatar,
      :message_signature,
      :account_id,
      ui_settings: {}
    )
  end

  def custom_attributes_params
    params.require(:profile).permit(:phone_number)
  end

  def password_params
    params.require(:profile).permit(
      :current_password,
      :password,
      :password_confirmation
    )
  end
end
