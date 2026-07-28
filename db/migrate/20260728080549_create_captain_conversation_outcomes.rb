class CreateCaptainConversationOutcomes < ActiveRecord::Migration[7.1]
  def change
    create_table :captain_conversation_outcomes do |t|
      add_dimensions(t)
      add_involvement_fields(t)
      add_handoff_fields(t)
      add_resolution_fields(t)
      add_experience_fields(t)
      t.timestamps
    end

    add_reporting_indexes
  end

  private

  def add_dimensions(table)
    table.references :account, null: false
    table.references :assistant, null: false
    table.references :conversation, null: false
    table.references :inbox, null: false
  end

  def add_involvement_fields(table)
    table.datetime :eligible_at, null: false
    table.datetime :captain_involved_at
    table.datetime :first_captain_reply_at
    table.datetime :last_captain_reply_at
    table.integer :captain_reply_count, null: false, default: 0
    table.datetime :first_human_reply_at
  end

  def add_handoff_fields(table)
    table.datetime :handoff_at
    table.string :handoff_reason_category
  end

  def add_resolution_fields(table)
    table.integer :resolution_type
    table.datetime :resolved_at
    table.datetime :first_reopened_at
    table.datetime :last_reopened_at
    table.integer :reopen_count, null: false, default: 0
    table.datetime :durable_resolved_at
  end

  def add_experience_fields(table)
    table.integer :first_response_seconds
    table.integer :resolution_seconds
    table.integer :csat_rating
    table.datetime :csat_received_at
  end

  def add_reporting_indexes
    add_index :captain_conversation_outcomes, [:account_id, :assistant_id, :conversation_id],
              unique: true, name: 'idx_captain_outcomes_unique_conversation'
    add_index :captain_conversation_outcomes, [:account_id, :assistant_id, :eligible_at],
              name: 'idx_captain_outcomes_on_assistant_eligible_at'
    add_index :captain_conversation_outcomes, [:account_id, :assistant_id, :resolved_at],
              name: 'idx_captain_outcomes_on_assistant_resolved_at'
    add_index :captain_conversation_outcomes, [:account_id, :assistant_id, :handoff_at],
              name: 'idx_captain_outcomes_on_assistant_handoff_at'
  end
end
