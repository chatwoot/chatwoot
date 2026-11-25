class AddHoldOnReplyToScheduledMessages < ActiveRecord::Migration[7.1]
  def change
    add_column :scheduled_messages, :hold_on_reply, :boolean, default: false, null: false
    add_column :recurring_scheduled_messages, :hold_on_reply, :boolean, default: false, null: false
  end
end
