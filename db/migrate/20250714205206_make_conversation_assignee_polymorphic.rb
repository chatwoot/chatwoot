class MakeConversationAssigneePolymorphic < ActiveRecord::Migration[7.1]
  def change
    add_column :conversations, :assignee_type, :string
    add_index :conversations, [:assignee_type, :assignee_id]

    # Update existing records to use User type
    reversible do |dir|
      dir.up do
        execute "UPDATE conversations SET assignee_type = 'User' WHERE assignee_id IS NOT NULL"
      end
    end
  end
end
