class Waha::StatusChangedService
  include Waha::ParamHelpers

  pattr_initialize [:inbox!, :params!]

  def perform
    message_id = params.dig(:message, :id) || params[:messageId]
    key = "status_changed_#{message_id}_#{params[:phone_number]}"

    if Redis::Alfred.get(key).present?
      Rails.logger.info("Duplicate status change event received for key: #{key}. Ignoring.")
      return
    end

    Redis::Alfred.set(key, true, ex: 60) # Set a TTL of 60 seconds to avoid duplicate processing

    return unless same_phone_number?

    broadcast_status_changed
  end

  private

  def same_phone_number?
    params[:phone_number] == channel.phone_number
  end

  def broadcast_status_changed
    event_data = {
      event: 'whatsapp_status_changed',
      type: 'phone_validation_success',
      status: 'logged_in',
      phone_number: channel.phone_number,
      session_id: params[:sessionID],
      connected: true,
      message: 'Phone number validation successful! WhatsApp is now connected.',
      inbox_id: inbox.id,
      channel_id: channel.id,
      account_id: inbox.account_id,
      timestamp: Time.current.iso8601,
      next_action: 'redirect_to_inbox'
    }
    broadcast(event_data)
  end

  def broadcast(event_data)
    pubsub_token = "#{inbox.account_id}_inbox_#{inbox.id}"

    ActionCable.server.broadcast(pubsub_token, {
                                   event: event_data[:event],
                                   type: event_data[:type],
                                   status: event_data[:status],
                                   phone_number: event_data[:phone_number],
                                   connected: event_data[:connected],
                                   message: event_data[:message],
                                   inbox_id: inbox.id,
                                   channel_id: channel.id,
                                   account_id: inbox.account_id,
                                   timestamp: Time.current.iso8601,
                                   next_action: event_data[:next_action] || nil
                                 })
  end

  def channel
    @channel ||= inbox.channel
  end
end
