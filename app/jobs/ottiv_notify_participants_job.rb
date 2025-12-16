class OttivNotifyParticipantsJob < ApplicationJob
  queue_as :default

  def perform(calendar_item_id)
    calendar_item = OttivCalendarItem.find(calendar_item_id)
    account = calendar_item.account

    # Nota: Os participantes já incluem o criador (garantido pelo CreateService)
    calendar_item.participants.each do |user|
      send_notifications_to_user(user, calendar_item, account)
    end

    Rails.logger.info "OttivNotifyParticipantsJob: Notified #{calendar_item.participants.count} participants for calendar item #{calendar_item.id}"
  rescue StandardError => e
    Rails.logger.error "OttivNotifyParticipantsJob: Error notifying participants for calendar item #{calendar_item_id}: #{e.message}"
  end

  private

  def send_notifications_to_user(user, calendar_item, account)
    # Criar notificação in-app
    create_in_app_notification(user, calendar_item, account)

    # TODO: Implementar push notification se configurado
    # send_push_notification(user, calendar_item) if user.has_push_enabled?

    # TODO: Implementar email se configurado
    # send_email_notification(user, calendar_item) if user.has_email_notifications_enabled?
  end

  def create_in_app_notification(user, calendar_item, account)
    # Usar o sistema de notificações do Chatwoot se disponível
    # Caso contrário, criar um registro de notificação personalizado

    notification_message = build_notification_message(calendar_item)

    # Tentar usar o sistema de notificações nativo do Chatwoot
    begin
      Notification.create!(
        account: account,
        user: user,
        notification_type: 'calendar_item',
        primary_actor_type: 'OttivCalendarItem',
        primary_actor_id: calendar_item.id,
        read_at: nil,
        # Adicionar metadados se suportado
        meta: {
          item_type: calendar_item.item_type,
          title: calendar_item.title,
          start_at: calendar_item.start_at,
          end_at: calendar_item.end_at
        }.compact
      )
    rescue StandardError => e
      # Fallback: Logar se o sistema de notificações não estiver disponível
      Rails.logger.warn "Could not create in-app notification: #{e.message}"
    end
  end

  def build_notification_message(calendar_item)
    type_label = case calendar_item.item_type
                 when 'reminder'
                   'Lembrete'
                 when 'event'
                   'Evento'
                 else
                   'Item da Agenda'
                 end

    start_time = calendar_item.start_at.strftime('%d/%m/%Y às %H:%M')

    "#{type_label}: #{calendar_item.title} - #{start_time}"
  end
end

