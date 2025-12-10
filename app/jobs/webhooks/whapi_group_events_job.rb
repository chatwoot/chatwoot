# frozen_string_literal: true

class Webhooks::WhapiGroupEventsJob < ApplicationJob
  queue_as :default

  def perform(event_type, payload_json)
    @event_type = event_type
    @payload = JSON.parse(payload_json)

    process_event
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP GROUPS] Event processing error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
  end

  private

  def process_event
    case @event_type
    when 'messages'
      process_message_event
    when 'statuses'
      process_status_event
    when 'groups'
      process_group_event
    else
      Rails.logger.info "[WHATSAPP GROUPS] Unhandled event type: #{@event_type}"
    end
  end

  def process_status_event
    # Handle message status updates for group messages
    statuses = @payload['statuses'] || [@payload['status']].compact

    statuses.each do |status_data|
      next unless status_data

      message_id = status_data['id']
      status = status_data['status']

      Rails.logger.info "[WHATSAPP GROUPS] Processing status update for message #{message_id}: #{status}"

      # Find message across all inboxes since this is a global webhook
      message = Message.find_by(source_id: message_id)
      unless message
        Rails.logger.warn "[WHATSAPP GROUPS] Message not found for source_id: #{message_id}"
        next
      end

      # Map Whapi status to Chatwoot status
      new_status = map_whapi_status(status)

      if new_status
        message.update(status: new_status)
        Rails.logger.info "[WHATSAPP GROUPS] Message #{message_id} status updated to #{new_status}"
      end
    end
  end

  def map_whapi_status(status)
    case status
    when 'sent', 'pending'
      :sent
    when 'delivered'
      :delivered
    when 'read'
      :read
    when 'failed', 'error'
      :failed
    else
      Rails.logger.info "[WHATSAPP GROUPS] Unknown status: #{status}"
      nil
    end
  end

  def process_message_event
    messages = @payload['messages'] || [@payload['message']]
    messages.each do |message_data|
      next unless message_data['chat_id']&.include?('@g.us')

      message_type = message_data['from_me'] ? 'outgoing' : 'incoming'
      Rails.logger.info "[WHATSAPP GROUPS] Processing #{message_type} group message: #{message_data['id']}"
      process_group_message(message_data)
    end
  end

  def process_group_message(message_data)
    group_id = message_data['chat_id']

    # Find the inbox and conversation for this group
    contact_inbox = ContactInbox.joins(:inbox)
                                .where(source_id: group_id)
                                .where(inboxes: { channel_type: 'Channel::Api' })
                                .first

    unless contact_inbox
      Rails.logger.warn "[WHATSAPP GROUPS] No contact_inbox found for group: #{group_id}"
      return
    end

    inbox = contact_inbox.inbox
    Rails.logger.info "[WHATSAPP GROUPS] Processing message for inbox: #{inbox.id}"

    # Use the existing IncomingMessageWhapiService to process the message
    Whatsapp::IncomingMessageWhapiService.new(
      inbox: inbox,
      params: message_data
    ).perform
  end

  def process_group_event
    # Handle group-specific events (group created, participant added/removed, etc.)
    Rails.logger.info "[WHATSAPP GROUPS] Group event received: #{@payload.inspect}"

    # You can add specific handling for group events here
    # For example: participant changes, group name updates, etc.
  end
end
