class Whatsapp::WhapiConnectionStatusService
  pattr_initialize [:channel!, :params!, :correlation_id]

  def perform
    return unless params['events']&.any?

    ActiveSupport::Notifications.instrument(
      'whapi.webhook',
      action: 'events',
      event_count: params['events'].size,
      channel_id: channel.id,
      correlation_id: correlation_id
    )

    params['events'].each do |event|
      process_connection_event(event)
    end
  end

  private

  def process_connection_event(event)
    case event['type']
    when 'ready', 'connected'
      handle_connected_event(event)
    when 'disconnected'
      handle_disconnected_event(event)
    else
      Rails.logger.info "[Whapi][#{correlation_id}] Unhandled event type: #{event['type']}"
    end
  end

  def handle_connected_event(event)
    phone_number = event['phone']
    return unless phone_number.present?

    # Ensure phone number is in E.164 format
    formatted_phone = phone_number.start_with?('+') ? phone_number : "+#{phone_number}"

    Rails.logger.info "[Whapi][#{correlation_id}] Channel #{channel.id} connected with phone: #{formatted_phone}"

    # Update webhook URL with phone number
    webhook_updated = false
    new_webhook_url = nil
    begin
      webhook_updated, new_webhook_url = update_webhook_with_phone_number(formatted_phone)
    rescue StandardError => e
      Rails.logger.warn "[Whapi][#{correlation_id}] Failed to update webhook with phone number: #{e.message}"
    end

    # Update channel with connected phone number and status
    config_object = channel.provider_config_object
    config_object.update_connection_status('connected')
    config_object.update_phone_number(formatted_phone)

    config_object.update_webhook_url(new_webhook_url) if webhook_updated && new_webhook_url.present?

    # Broadcast status update for UI
    broadcast_connection_status('connected')
    ActiveSupport::Notifications.instrument(
      'whapi.onboarding',
      action: 'connected',
      channel_id: channel.id,
      inbox_id: channel.inbox.id,
      correlation_id: correlation_id
    )
  end

  def handle_disconnected_event(_event)
    Rails.logger.info "[Whapi][#{correlation_id}] Channel #{channel.id} disconnected"

    channel.update!(
      provider_config: channel.provider_config.merge(
        'connection_status' => 'disconnected',
        'disconnected_at' => Time.current.iso8601
      )
    )

    # Broadcast status update for UI
    broadcast_connection_status('disconnected')
    ActiveSupport::Notifications.instrument(
      'whapi.onboarding',
      action: 'disconnected',
      channel_id: channel.id,
      inbox_id: channel.inbox.id,
      correlation_id: correlation_id
    )
  end

  def update_webhook_with_phone_number(formatted_phone)
    channel_token = channel.provider_config_object.whapi_channel_token
    return [false, nil] unless channel_token.present?

    service = Whatsapp::Partner::WhapiPartnerService.new
    new_webhook_url = service.update_webhook_with_phone_number(
      channel_token: channel_token,
      phone_number: formatted_phone
    )

    Rails.logger.info "[Whapi][#{correlation_id}] Webhook updated with phone number: #{formatted_phone}, new URL: #{new_webhook_url}"
    [true, new_webhook_url]
  end

  def broadcast_connection_status(status)
    ActionCable.server.broadcast(
      "account_#{channel.account_id}",
      {
        event: 'whapi_channel_status_updated',
        data: {
          account_id: channel.account_id,
          inbox_id: channel.inbox.id,
          connection_status: status,
          phone_number: channel.phone_number,
          correlation_id: correlation_id
        }
      }
    )
  end
end

