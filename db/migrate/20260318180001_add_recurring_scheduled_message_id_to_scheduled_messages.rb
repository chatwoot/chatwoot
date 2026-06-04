class AddRecurringScheduledMessageIdToScheduledMessages < ActiveRecord::Migration[7.0]
  def change
    add_reference :scheduled_messages, :recurring_scheduled_message,
                  null: true, foreign_key: true, index: true
  end
end
