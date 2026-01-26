class CreateEnrollmentEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :enrollment_events do |t|
      t.references :sequence_enrollment, null: false, foreign_key: true, index: true
      t.references :conversation, null: false, foreign_key: true, index: true
      t.references :lead_follow_up_sequence, null: false, foreign_key: true, index: true
      t.string :event_type, null: false
      t.string :step_id
      t.integer :step_index
      t.datetime :occurred_at, null: false
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :enrollment_events, [:conversation_id, :occurred_at],
              name: 'index_events_on_conversation_occurred'
    add_index :enrollment_events, [:sequence_enrollment_id, :occurred_at],
              name: 'index_events_on_enrollment_occurred'
    add_index :enrollment_events, :event_type
    add_index :enrollment_events, :occurred_at
  end
end
