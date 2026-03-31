class CreateConversationReengagements < ActiveRecord::Migration[7.0]
  def change
    create_table :conversation_reengagements do |t|
      t.references :conversation, null: false, foreign_key: true, index: { unique: true }
      t.references :agent_bot,    null: false, foreign_key: true
      t.string     :status,       null: false, default: 'active'
      t.integer    :current_attempt, null: false, default: 0
      t.datetime   :trigger_started_at
      t.datetime   :next_fire_at
      t.datetime   :last_attempt_fired_at
      t.datetime   :processing_started_at
      t.jsonb      :metadata, null: false, default: {}
      t.timestamps
    end

    add_index :conversation_reengagements, [:status, :next_fire_at]
    add_index :conversation_reengagements, :processing_started_at
  end
end
