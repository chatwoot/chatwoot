class CreateConversationHandledByTags < ActiveRecord::Migration[7.0]
  def change
    create_table :conversation_handled_by_tags do |t|
      t.references :conversation, null: false, foreign_key: true
      t.references :user, null: true, foreign_key: true
      t.string :handled_by
      t.timestamps
    end
  end
end
