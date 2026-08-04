class CreateConversationOutcomes < ActiveRecord::Migration[7.1]
  def change
    create_table :conversation_outcomes do |t|
      t.references :account, null: false
      t.references :assistant, null: false
      t.references :conversation, null: false
      t.references :inbox, null: false

      t.datetime :first_captain_reply_at
      t.datetime :last_captain_reply_at
      t.integer :captain_reply_count, null: false, default: 0
      t.datetime :first_human_reply_at

      t.datetime :handoff_at
      t.string :handoff_reason_category

      t.datetime :resolved_at
      t.datetime :last_reopened_at
      t.integer :reopen_count, null: false, default: 0

      t.integer :csat_rating
      t.datetime :csat_received_at

      t.timestamps
    end

    add_reporting_indexes
  end

  private

  def add_reporting_indexes
    add_index :conversation_outcomes, [:account_id, :assistant_id, :conversation_id],
              unique: true, name: 'idx_conversation_outcomes_unique_conversation'
    add_index :conversation_outcomes, [:account_id, :assistant_id, :resolved_at],
              name: 'idx_conversation_outcomes_on_assistant_resolved_at'
    add_index :conversation_outcomes, [:account_id, :assistant_id, :handoff_at],
              name: 'idx_conversation_outcomes_on_assistant_handoff_at'
    add_index :conversation_outcomes, [:account_id, :assistant_id, :created_at],
              name: 'idx_conversation_outcomes_on_assistant_created_at'
  end
end
