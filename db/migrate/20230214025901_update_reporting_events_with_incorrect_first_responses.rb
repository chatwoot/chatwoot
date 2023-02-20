class UpdateReportingEventsWithIncorrectFirstResponses < ActiveRecord::Migration[6.1]
  include ReportingEventHelper

  # rubocop:disable Metrics/AbcSize
  def change
    ReportingEvent.where(name: 'first_response', user_id: nil).find_in_batches do |bot_responses|
      bot_responses.each do |event|
        conversation = event.conversation
        next if conversation.nil?

        last_bot_reply = conversation.messages.where(sender_type: 'AgentBot').order(created_at: :asc).last
        first_human_reply = conversation.message.where(sender_type: 'User').order(created_at: :asc).first

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

        next if last_bot_reply.blank?

        # this means a bot replied existed, so we need to update the event_start_time
        # rubocop:disable Rails/SkipsModelValidations
        event.update_columns(event_start_time: last_bot_reply.created_at,
                             event_end_time: first_human_reply.created_at,
                             value: first_human_reply.created_at.to_i - last_bot_reply.created_at.to_i,
                             value_in_business_hours: business_hours(conversation.inbox, last_bot_reply.created_at, first_human_reply.created_at),
                             user_id: first_human_reply.sender_id)

        # rubocop:enable Rails/SkipsModelValidations
      end
    end
  end
  # rubocop:enable Metrics/AbcSize
end
