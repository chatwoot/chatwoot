class Api::V1::Accounts::OttivNotificationsController < Api::V1::Accounts::BaseController
  before_action :set_user
  before_action :check_authorization

  def create
    begin
      @notification = @user.ottiv_notifications.build(notification_params)
      @notification.account_id = Current.account.id

      Rails.logger.info("📝 [OttivNotifications] Criando notificação para user #{@user.id}, account #{Current.account.id}")
      Rails.logger.info("   Type: #{@notification.notification_type}")
      Rails.logger.info("   Primary Actor: #{@notification.primary_actor_type}##{@notification.primary_actor_id}")

      if @notification.save
        Rails.logger.info("✅ [OttivNotifications] Notificação #{@notification.id} criada com sucesso")
        render 'api/v1/accounts/ottiv_notifications/create', status: :created
      else
        Rails.logger.error("❌ [OttivNotifications] Erro ao criar notificação: #{@notification.errors.full_messages.join(', ')}")
        render json: { errors: @notification.errors.full_messages }, status: :unprocessable_entity
      end
    rescue StandardError => e
      Rails.logger.error("❌ [OttivNotifications] Exception ao criar notificação: #{e.class} - #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      render json: { error: 'Internal server error', message: e.message }, status: :internal_server_error
    end
  end

  private

  def notification_params
    params.require(:ottiv_notification).permit(
      :user_id,
      :notification_type,
      :primary_actor_type,
      :primary_actor_id,
      :secondary_actor_type,
      :secondary_actor_id,
      meta: {}
    )
  end

  def set_user
    user_id = notification_params[:user_id]
    @user = User.find(user_id)
  rescue ActiveRecord::RecordNotFound
    Rails.logger.error("❌ [OttivNotifications] User não encontrado: #{user_id}")
    render json: { error: 'User not found' }, status: :not_found
  end

  def check_authorization
    # Verificar se o usuário pertence à conta
    account_user = Current.account.account_users.find_by(user_id: @user.id)
    unless account_user
      Rails.logger.error("❌ [OttivNotifications] User #{@user.id} não pertence à account #{Current.account.id}")
      render json: { error: 'User does not belong to this account' }, status: :forbidden
    end
  end
end

