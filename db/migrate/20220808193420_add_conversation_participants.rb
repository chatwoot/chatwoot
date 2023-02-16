class AddConversationParticipants < ActiveRecord::Migration[6.1]
  def change
    create_table 'conversation_participants', force: :cascade do |t|
      t.references :account, null: false
      t.references :user, null: false
      t.references :conversation, null: false
      t.datetime 'created_at', precision: 6, null: false
      t.datetime 'updated_at', precision: 6, null: false
    end
  end
end
