class Api::V1::Accounts::OttivNotificationsController < Api::V1::Accounts::BaseController
  before_action :set_user
  before_action :check_authorization
  before_action :validate_primary_actor, only: [:create]

  def create
    begin
      # ✅ Construir notificação SEM primary_actor_type e primary_actor_id
      # Isso evita que o Rails tente buscar a conversa antes de termos o objeto
      params_without_primary = notification_params.except(:primary_actor_type, :primary_actor_id)
      @notification = @user.ottiv_notifications.build(params_without_primary)
      @notification.account_id = Current.account.id

      # ✅ Atribuir o objeto primary_actor diretamente (como NotificationBuilder faz)
      @notification.primary_actor = @primary_actor if @primary_actor

      # ✅ Atribuir secondary_actor se fornecido
      if notification_params[:secondary_actor_type].present? && notification_params[:secondary_actor_id].present?
        case notification_params[:secondary_actor_type]
        when 'Message'
          @notification.secondary_actor = Current.account.messages.find_by(id: notification_params[:secondary_actor_id])
        end
      end

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

  # ✅ Validar e buscar primary_actor garantindo que pertence ao account correto
  def validate_primary_actor
    primary_actor_type = notification_params[:primary_actor_type]
    primary_actor_id = notification_params[:primary_actor_id]

    return if primary_actor_type.blank? || primary_actor_id.blank?
    case primary_actor_type
    when 'Conversation'
      # ✅ Buscar conversa por account_id + display_id (chave composta)
      # O primary_actor_id que vem do webhook é o display_id, não o id real
      # Usar busca explícita para aproveitar o índice único (account_id, display_id)
      @primary_actor = Conversation.find_by(
        account_id: Current.account.id,
        display_id: primary_actor_id
      )
      unless @primary_actor
        Rails.logger.error("❌ [OttivNotifications] Conversation com display_id #{primary_actor_id} não encontrada no account #{Current.account.id}")
        render json: { errors: ['Primary actor must exist and belong to the account'] }, status: :unprocessable_entity
        return
      end
    else
      Rails.logger.error("❌ [OttivNotifications] Primary actor type não suportado: #{primary_actor_type}")
      render json: { errors: ['Unsupported primary actor type'] }, status: :unprocessable_entity
      return
    end
  end
end

