class CreateCaptainAgentTraces < ActiveRecord::Migration[7.1]
  def change
    create_table :captain_agent_traces do |t|
      t.string :source, null: false, default: 'conversation'
      t.string :input_message
      t.jsonb :trace, null: false, default: []
      t.jsonb :response, null: false, default: {}
      t.string :outcome, null: false, default: 'answered'
      t.string :error_reason

      t.references :account, null: false, foreign_key: true
      t.references :assistant, null: false, foreign_key: { to_table: :captain_assistants }
      t.references :conversation, null: true, foreign_key: true

      t.timestamps
    end

    add_index :captain_agent_traces, [:assistant_id, :created_at]
    add_index :captain_agent_traces, [:conversation_id, :created_at]
    add_index :captain_agent_traces, [:source, :created_at]
  end
end