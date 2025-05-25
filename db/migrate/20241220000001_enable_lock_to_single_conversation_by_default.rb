class EnableLockToSingleConversationByDefault < ActiveRecord::Migration[7.0]
  def up
    # Update all existing inboxes to enable lock_to_single_conversation
    execute <<-SQL
      UPDATE inboxes 
      SET lock_to_single_conversation = true 
      WHERE lock_to_single_conversation = false;
    SQL

    # Change the default value for future inboxes
    change_column_default :inboxes, :lock_to_single_conversation, from: false, to: true
  end

  def down
    # Revert all inboxes to disabled lock_to_single_conversation
    execute <<-SQL
      UPDATE inboxes 
      SET lock_to_single_conversation = false 
      WHERE lock_to_single_conversation = true;
    SQL

    # Revert the default value
    change_column_default :inboxes, :lock_to_single_conversation, from: true, to: false
  end
end
