# Delete migration and spec after 2 consecutive releases.
class Migration::UpdateFirstResponseTimeInReportingEventsJob < ApplicationJob
  include ReportingEventHelper

  queue_as :async_database_migration

  def perform(account)
    get_conversations_with_bot_handoffs(account)
    account.reporting_events.where(name: 'first_response').find_each do |event|
      conversation = event.conversation

      # if the conversation has a bot handoff event, we don't need to update the response_time
      next if conversation.nil? || @conversations_with_handoffs.include?(conversation.id)

      update_event_data(event, conversation)
    end
  end

  def get_conversations_with_bot_handoffs(account)
    @conversations_with_handoffs = account.reporting_events.where(name: 'conversation_bot_handoff').pluck(:conversation_id)
  end

  def update_event_data(event, conversation)
    last_bot_reply = conversation.messages.where(sender_type: 'AgentBot').order(created_at: :asc).last
    return if last_bot_reply.blank?

    first_human_reply = conversation.messages.where(sender_type: 'User').order(created_at: :asc).first
    return if first_human_reply.blank?

    # accomodate for campaign if required
    # new_value = difference between the first_human_reply and the first_bot_reply if it exists or first_human_reply and created at
    #
    # conversation       bot                         conversation
    # start              handoff                     resolved
    # |                  |                           |
    # |____|___|_________|____|_______|_____|________|
    #      bot reply     ^    ^  human reply
    #                    |    |
    #                    |    |
    #       last_bot_reply    first_human_reply
    #
    #
    # bot handoff happens at the last_bot_reply created time
    # the response time is the time between last bot reply created and the first human reply created
    return if last_bot_reply.created_at.to_i >= first_human_reply.created_at.to_i

    # this means a bot replied existed, so we need to update the event_start_time
    update_event_details(event, last_bot_reply, first_human_reply, conversation.inbox)
  end

  def update_event_details(event, last_bot_reply, first_human_reply, inbox)
    # rubocop:disable Rails/SkipsModelValidations
    event.update_columns(event_start_time: last_bot_reply.created_at,
                         event_end_time: first_human_reply.created_at,
                         value: calculate_event_value(last_bot_reply, first_human_reply),
                         value_in_business_hours: calculate_event_value_in_business_hours(inbox, last_bot_reply,
                                                                                          first_human_reply),
                         user_id: event.user_id || first_human_reply.sender_id)
    # rubocop:enable Rails/SkipsModelValidations
  end

  def calculate_event_value(last_bot_reply, first_human_reply)
    first_human_reply.created_at.to_i - last_bot_reply.created_at.to_i
  end

  def calculate_event_value_in_business_hours(inbox, last_bot_reply, first_human_reply)
    business_hours(inbox, last_bot_reply.created_at, first_human_reply.created_at)
  end
end
