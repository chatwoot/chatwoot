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

  def perform(members, event_name, data)
    return if members.blank?

    broadcast_data = prepare_broadcast_data(event_name, data)
    broadcast_to_members(members, event_name, broadcast_data)
  end

  private

  # Ensures that only the latest available data is sent to prevent UI issues
  # caused by out-of-order events during high-traffic periods. This prevents
  # the conversation job from processing outdated data.
  def prepare_broadcast_data(event_name, data)
    return data unless CONVERSATION_UPDATE_EVENTS.include?(event_name)

    account = Account.find(data[:account_id])
    conversation = account.conversations.find_by!(display_id: data[:id])
    broadcast_data = conversation.push_event_data.merge(data.slice(:account_id, :performer))
    if event_name == ASSIGNEE_CHANGED
      # Refreshing the conversation must not attribute a later assignee to the
      # original assignment source. Replace the whole metadata object, including
      # explicit unknown provenance, so a previous source cannot linger locally.
      assignment_changed =
        data.dig(:meta, :assignee_type) != broadcast_data.dig(:meta, :assignee_type) ||
        data.dig(:meta, :assignee, :id) != broadcast_data.dig(:meta, :assignee, :id)
      # Keep the assignment's original identity and time together. Other cable
      # events omit this field, so their performers cannot overwrite it in Vuex.
      # Jobs queued before this contract also have unknown assignment provenance.
      broadcast_data[:assignment] = {
        source: assignment_changed ? 'unknown' : assignment_source(data),
        assignee_id: data.dig(:meta, :assignee, :id),
        assignee_type: data.dig(:meta, :assignee_type),
        updated_at: data[:updated_at]
      }
    end
    broadcast_data
  end

  def assignment_source(data)
    # Explicit auto-assignment wins over an ambient API user. A missing actor
    # (including jobs queued before this contract) never proves auto-assignment.
    return 'automatic' if data[:automatic_assignment]
    return 'human' if data.dig(:performer, :type) == 'user'

    'unknown'
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
