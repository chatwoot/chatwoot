class CreateConversationHandledByTags < ActiveRecord::Migration[7.0]
  def change
    create_table :conversation_handled_by_tags do |t|
      t.references :conversation, null: false
      t.references :user, null: true
      t.string :handled_by
      t.timestamps
    end
  end
end
