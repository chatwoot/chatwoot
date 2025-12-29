class CreateConversationFollowUps < ActiveRecord::Migration[7.1]
  def change
    create_table :conversation_follow_ups do |t|
      t.references :conversation, null: false, foreign_key: true, index: { unique: true }
      t.references :lead_follow_up_sequence, null: false, foreign_key: true, index: true

      t.integer :current_step, default: 0, null: false
      t.datetime :next_action_at
      t.string :status, default: 'active', null: false
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :conversation_follow_ups, [:status, :next_action_at]
  end
end
