# frozen_string_literal: true

class Webhooks::WhapiEventsJob < ApplicationJob
  queue_as :default

  def perform(inbox_id, event_type, payload_json)
    @inbox = Inbox.find_by(id: inbox_id)
    return unless @inbox
    return unless @inbox.channel.is_a?(Channel::Whatsapp)
    return unless @inbox.channel.provider == 'whatsapp_light'

    @event_type = event_type
    @payload = JSON.parse(payload_json)

    process_event
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP LIGHT] Event processing error for inbox #{inbox_id}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
  end

  private

  def process_event
    case @event_type
    when 'messages'
      process_message_event
    when 'statuses'
      process_status_event
    when 'chats'
      process_chat_event
    when 'channel', 'users', 'presences', 'contacts', 'groups', 'labels', 'calls'
      # These events are informational, log them but don't need processing for now
      Rails.logger.info "[WHATSAPP LIGHT] Received #{@event_type} event: #{@payload.inspect}"
    else
      Rails.logger.info "[WHATSAPP LIGHT] Unhandled event type: #{@event_type}"
    end
  end

  def process_message_event
    messages = @payload['messages'] || [@payload['message']]
    messages.each do |message_data|
      if message_data['from_me']
        Rails.logger.info "[WHATSAPP LIGHT] Skipping outgoing message: #{message_data['id']}"
        next
      end

      Rails.logger.info "[WHATSAPP LIGHT] Processing incoming message: #{message_data['id']}"
      Whatsapp::IncomingMessageWhapiService.new(
        inbox: @inbox,
        params: message_data
      ).perform
    end
  end

  def process_status_event
    # Handle message status updates (sent, delivered, read, etc.)
    # Whapi sends statuses as an array
    statuses = @payload['statuses'] || [@payload['status']].compact

    statuses.each do |status_data|
      next unless status_data

      message_id = status_data['id']
      status = status_data['status']

      Rails.logger.info "[WHATSAPP LIGHT] Processing status update for message #{message_id}: #{status}"

      message = @inbox.messages.find_by(source_id: message_id)
      unless message
        Rails.logger.warn "[WHATSAPP LIGHT] Message not found for source_id: #{message_id}"
        next
      end

      # Map Whapi status to Chatwoot status
      new_status = case status
                   when 'sent', 'pending'
                     :sent
                   when 'delivered'
                     :delivered
                   when 'read'
                     :read
                   when 'failed', 'error'
                     :failed
                   else
                     Rails.logger.info "[WHATSAPP LIGHT] Unknown status: #{status}"
                     nil
                   end

      if new_status
        message.update(status: new_status)
        Rails.logger.info "[WHATSAPP LIGHT] Message #{message_id} status updated to #{new_status}"
      end
    end
  end

  def process_chat_event
    # Handle chat events (new chat, chat archived, etc.)
    Rails.logger.info "[WHATSAPP LIGHT] Chat event received: #{@payload.inspect}"
  end
end
