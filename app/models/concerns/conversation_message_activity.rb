module ConversationMessageActivity
  extend ActiveSupport::Concern

  class_methods do
    def sort_on_last_message_at(sort_direction)
      timestamp = arel_table[:last_message_at]
      order(timestamp.public_send(sort_direction).nulls_last, display_id: sort_direction)
    end

    def with_last_message_before(timestamp)
      column = arel_table[:last_message_at]
      where(column.eq(nil).or(column.lt(timestamp)))
    end

    def advance_last_message_at(conversation_id, timestamp)
      where(id: conversation_id).with_last_message_before(timestamp).update_all(last_message_at: timestamp) # rubocop:disable Rails/SkipsModelValidations
    end
  end

  # Called inside the message INSERT transaction. A normal public message writes
  # both clocks in one UPDATE, which also updates the instance used in broadcasts.
  def record_message_activity!(message)
    activity = { last_activity_at: message.created_at, updated_at: Time.current }
    if message.public_chat_message?
      earlier = self.class.where(account_id: account_id).with_last_message_before(message.created_at)
      advanced = earlier.scoping(all_queries: true) do
        update_columns(activity.merge(last_message_at: message.created_at)) # rubocop:disable Rails/SkipsModelValidations
      end
      return if advanced
    end

    update_columns(activity) # rubocop:disable Rails/SkipsModelValidations
    # A failed conditional update still assigns its arguments in memory. Read the
    # winning timestamp before broadcasting an out-of-order public message.
    reload if message.public_chat_message?
  end
end
