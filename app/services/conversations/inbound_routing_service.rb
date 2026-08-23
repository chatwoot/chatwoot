# Single abstraction that decides who owns an inbound message's conversation:
# the Captain AI agent or a human agent. Every inbound channel funnels through
# this service (via the Message create callback -> HookExecutionService), so the
# captain-vs-human decision is made in one place instead of being spread across
# per-inbox/per-channel services.
#
# A conversation is "owned" by Captain while it is in the `pending` status.
# Conversations are optimistically pended at creation on Captain-connected
# inboxes, so this service must guarantee a pended conversation is never left in
# limbo: if Captain declines the message (e.g. an external bot is active), the
# conversation is handed to the human queue so auto-assignment picks it up.
class Conversations::InboundRoutingService
  pattr_initialize [:message!]

  delegate :inbox, :conversation, to: :message

  # Routes the conversation and returns the owner: :captain or :human.
  #
  # Only inbound messages pick an owner. Outgoing messages (an assistant reply, a
  # human reply, a template, an echo) must never trigger a status transition here:
  # route_to_human would force a pending Captain conversation open on every
  # assistant reply. Guarding at this entry point keeps every caller safe.
  def perform
    return unless message.incoming?

    if route_to_captain?
      schedule_captain_response
      :captain
    else
      route_to_human
      :human
    end
  end

  private

  def route_to_captain?
    return false unless message.captain_response_triggering?
    return false if inbox.captain_assistant.blank?
    return false if inbox.external_bot_active?

    engage_captain_for_conversation
    conversation.pending?
  end

  # Conversations created before the assistant was attached (or reused ones that
  # are still open) are pended here so the first customer message hands them to
  # Captain, unless a human is already working the thread.
  def engage_captain_for_conversation
    return if conversation.pending?
    return unless conversation_available_for_captain?

    conversation.pending!
  end

  # Captain may take an open conversation when the humans it's assigned to are
  # offline, so a customer isn't left waiting on an agent who isn't responding.
  # Unassigned conversations are fair game; an assigned one is handed to Captain
  # only when none of its assignees (or the assigned team's members) is online.
  # A conversation with an existing human reply is NOT auto-taken; an agent can
  # still opt it in manually with the per-conversation bot-reply toggle.
  def conversation_available_for_captain?
    return false unless conversation.open?
    return true if captain_reply_manually_enabled?
    return false if conversation.first_reply_created_at.present?
    return false if assigned_agent_online?

    true
  end

  # A `pending` conversation means Captain owns it. If Captain won't handle this
  # message, do not leave it dangling: open it so the human auto-assignment queue
  # claims it. Already-open conversations are already in the human queue.
  def route_to_human
    conversation.open! if conversation.pending?
  end

  def schedule_captain_response
    Captain::Conversation::ResponseSchedulerService.new(message: message).perform
  end

  def captain_reply_manually_enabled?
    conversation.custom_attributes['ai_reply_enabled'].to_s == 'true'
  end

  def assigned_agent_online?
    conversation_assignee_user_ids.intersect?(online_user_ids)
  end

  def conversation_assignee_user_ids
    user_ids = [conversation.assignee_id]
    user_ids += conversation.team&.members&.pluck(:user_id) if conversation.team_id.present?
    user_ids.compact.uniq
  end

  def online_user_ids
    ::OnlineStatusTracker.get_available_users(conversation.account_id)
                         .select { |_user_id, status| status.eql?('online') }
                         .keys
                         .map(&:to_i)
  end
end
