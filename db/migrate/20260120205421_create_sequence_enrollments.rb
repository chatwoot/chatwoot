class CreateSequenceEnrollments < ActiveRecord::Migration[7.1]
  def change
    create_table :sequence_enrollments do |t|
      t.references :conversation, null: false, foreign_key: true, index: true
      t.references :lead_follow_up_sequence, null: false, foreign_key: true, index: true
      t.datetime :enrolled_at, null: false
      t.datetime :completed_at
      t.string :status, null: false, default: 'active'
      t.string :completion_reason
      t.integer :current_step, default: 0
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :sequence_enrollments, [:conversation_id, :lead_follow_up_sequence_id, :enrolled_at],
              name: 'index_enrollments_on_conv_sequence_enrolled'
    add_index :sequence_enrollments, :status
    add_index :sequence_enrollments, :enrolled_at
    add_index :sequence_enrollments, :completed_at
  end
end
