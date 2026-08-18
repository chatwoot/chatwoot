class AddSoftDeleteAndActivitiesToCalendarEvents < ActiveRecord::Migration[7.1]
  def change
    add_column :calendar_events, :deleted_at, :datetime
    add_reference :calendar_events, :deleted_by, foreign_key: { to_table: :users }
    add_index :calendar_events, :deleted_at

    create_table :calendar_event_activities do |t|
      t.references :account, null: false, foreign_key: true
      t.references :calendar_event, null: false, foreign_key: true
      t.references :user, foreign_key: { to_table: :users }
      t.string :action, null: false
      t.jsonb :details, null: false, default: {}
      t.timestamps
    end

    add_index :calendar_event_activities, [:calendar_event_id, :created_at],
              name: 'idx_calendar_event_activities_on_event_and_created'
  end
end
