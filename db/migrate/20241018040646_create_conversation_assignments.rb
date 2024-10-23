class CreateConversationAssignments < ActiveRecord::Migration[7.0]
  def change
    create_table :conversation_assignments do |t|
      t.references :conversation, null: false, index: true
      t.references :account, null: false, index: true
      t.references :inbox, null: false, index: true
      t.references :assignee, null: false, index: true
      t.references :team, index: true

      t.timestamps
    end
  end
end
