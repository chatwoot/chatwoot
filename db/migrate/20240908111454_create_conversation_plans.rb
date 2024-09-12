class CreateConversationPlans < ActiveRecord::Migration[7.0]
  def change
    create_table :conversation_plans do |t|
      t.bigint 'account_id', null: false
      t.bigint 'contact_id'
      t.bigint 'conversation_id', null: false
      t.bigint 'created_by_id', null: false
      t.string 'description'
      t.datetime 'completed_at'
      t.index ['account_id'], name: 'index_conversation_plans_on_account_id'
      t.index ['contact_id'], name: 'index_conversation_plans_on_contact_id'
      t.index ['conversation_id'], name: 'index_conversation_plans_on_conversation_id'
      t.index ['created_by_id'], name: 'index_conversation_plans_on_created_by_id'
      t.timestamps
    end
  end
end
