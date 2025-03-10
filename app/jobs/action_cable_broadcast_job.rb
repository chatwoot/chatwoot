class ActionCableBroadcastJob < ApplicationJob
  queue_as :critical
  include Events::Types

  CONVERSATION_UPDATE_EVENTS = [
    CONVERSATION_READ,
    CONVERSATION_UPDATED,
    TEAM_CHANGED,
    ASSIGNEE_CHANGED,
    CONVERSATION_STATUS_CHANGED
  ].freeze

  def perform(members, event_name, data, event_timestamp)
    return if members.blank?

    broadcast_data = prepare_broadcast_data(event_name, data)
    broadcast_to_members(members, event_name, broadcast_data, event_timestamp)
  end

  private

  # Ensures that only the latest available data is sent to prevent UI issues
  # caused by out-of-order events during high-traffic periods. This prevents
  # the conversation job from processing outdated data.
  def prepare_broadcast_data(event_name, data)
    return data unless CONVERSATION_UPDATE_EVENTS.include?(event_name)

    account = Account.find(data[:account_id])
    conversation = account.conversations.find_by!(display_id: data[:id])
    conversation.push_event_data.merge(account_id: data[:account_id])
  end

  # A timestamp is added to the broadcast data, this timestamp is
  # generated in the main app thread when the job is enqueued.
  # This is used as a "sequence number" to ensure we ignore out of order events
  def broadcast_to_members(members, event_name, broadcast_data, event_timestamp)
    members.each do |member|
      ActionCable.server.broadcast(
        member,
        {
          event: event_name,
          data: broadcast_data,
          event_timestamp: event_timestamp
        }
      )
    end
  end
end
