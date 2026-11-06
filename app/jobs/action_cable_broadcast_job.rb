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

  # widget_members are web widget sessions. They get widget_data, or the widget payload of a refreshed conversation.
  def perform(members, event_name, data, widget_members: [], widget_data: nil)
    return if members.blank? && widget_members.blank?

    conversation = latest_conversation(event_name, data)
    broadcast_to_members(members, event_name, conversation ? refreshed_data(conversation, event_name, data) : data)
    broadcast_to_members(widget_members, event_name, conversation ? refreshed_widget_data(conversation, data) : widget_data)
  end

  private

  # Ensures that only the latest available data is sent to prevent UI issues
  # caused by out-of-order events during high-traffic periods. This prevents
  # the conversation job from processing outdated data.
  def latest_conversation(event_name, data)
    return unless CONVERSATION_UPDATE_EVENTS.include?(event_name)

    Account.find(data[:account_id]).conversations.find_by!(display_id: data[:id])
  end

  def refreshed_data(conversation, event_name, data)
    broadcast_data = conversation.push_event_data.merge(account_id: data[:account_id])
    if event_name == ASSIGNEE_CHANGED
      # Keep the original assignment together even when the conversation is
      # refreshed. The dashboard checks its identity against the current owner.
      # Other events omit this field so unrelated updates cannot overwrite it.
      broadcast_data[:assignment] = {
        automatic: data[:automatic_assignment] == true,
        assignee_id: data.dig(:meta, :assignee, :id),
        assignee_type: data.dig(:meta, :assignee_type),
        updated_at: data[:updated_at]
      }
    end
    broadcast_data
  end

  def refreshed_widget_data(conversation, data)
    conversation.widget_push_event_data.merge(account_id: data[:account_id])
  end

  def broadcast_to_members(members, event_name, broadcast_data)
    members.each do |member|
      ActionCable.server.broadcast(
        member,
        {
          event: event_name,
          data: broadcast_data
        }
      )
    end
  end
end
