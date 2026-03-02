class AddStatusConversationCountersToAccounts < ActiveRecord::Migration[7.1]
  def change
    add_column :accounts, :open_conversations_count, :integer, default: 0, null: false
    add_column :accounts, :resolved_conversations_count, :integer, default: 0, null: false
    add_column :accounts, :pending_conversations_count, :integer, default: 0, null: false
    add_column :accounts, :snoozed_conversations_count, :integer, default: 0, null: false
  end
end
