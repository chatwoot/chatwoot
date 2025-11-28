class Api::V1::Accounts::OttivNotificationSettingsController < Api::V1::Accounts::BaseController
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
    begin
      # ✅ Criar setting se não existir (find_or_initialize_by)
      @notification_setting = @user.ottiv_notification_settings.find_or_initialize_by(
        account_id: Current.account.id
      )

      # Se for um novo registro, garantir que tenha user_id e valores padrão antes de salvar
      if @notification_setting.new_record?
        @notification_setting.user_id = @user.id
        @notification_setting.account_id = Current.account.id
        @notification_setting.email_flags = 0 unless @notification_setting.email_flags
        @notification_setting.push_flags = 0 unless @notification_setting.push_flags
        @notification_setting.save!
        # Recarregar o registro para garantir que os métodos dinâmicos estejam disponíveis
        @notification_setting.reload
      end
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error("Failed to create ottiv_notification_setting: #{e.message}")
      Rails.logger.error("Record errors: #{@notification_setting&.errors&.full_messages&.join(', ')}")
      Rails.logger.error(e.backtrace.join("\n"))
      raise
    rescue StandardError => e
      Rails.logger.error("Error loading ottiv_notification_setting: #{e.class} - #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      raise
    end
  end

  def notification_setting_params
    params.require(:notification_settings).permit(selected_email_flags: [], selected_push_flags: [])
  end

  def update_flags
    @notification_setting.selected_email_flags = notification_setting_params[:selected_email_flags]
    @notification_setting.selected_push_flags = notification_setting_params[:selected_push_flags]
  end
end

