class Api::V1::Accounts::NotificationSettingsController < Api::V1::Accounts::BaseController
  before_action :set_user, :load_notification_setting

  def show; end

  def update
    update_flags
    @notification_setting.save!
    render action: 'show'
  end

  private

  def set_user
    @user = current_user
  end

  def load_notification_setting
    @notification_setting = @user.notification_settings.find_by(account_id: Current.account.id)
  end

  def notification_setting_params
    params.require(:notification_settings).permit

    permitted = {}
    # Manually permit all array values to avoid strong_parameters filtering
    if params[:notification_settings][:selected_email_flags].present?
      permitted[:selected_email_flags] = params[:notification_settings][:selected_email_flags]
    end

    if params[:notification_settings][:selected_push_flags].present?
      permitted[:selected_push_flags] = params[:notification_settings][:selected_push_flags]
    end

    if params[:notification_settings][:selected_whatsapp_flags].present?
      permitted[:selected_whatsapp_flags] = params[:notification_settings][:selected_whatsapp_flags]
    end

    permitted
  end

  def update_flags
    @notification_setting.selected_email_flags = notification_setting_params[:selected_email_flags] if notification_setting_params.key?(:selected_email_flags)
    @notification_setting.selected_push_flags = notification_setting_params[:selected_push_flags] if notification_setting_params.key?(:selected_push_flags)
    @notification_setting.selected_whatsapp_flags = notification_setting_params[:selected_whatsapp_flags] if notification_setting_params.key?(:selected_whatsapp_flags)
  end
end
