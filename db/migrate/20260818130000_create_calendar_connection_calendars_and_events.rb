class CreateCalendarConnectionCalendarsAndEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :calendar_connection_calendars do |t|
      t.references :account, null: false, foreign_key: true
      t.references :calendar_connection, null: false, foreign_key: true
      t.string :external_id, null: false
      t.string :summary, null: false, default: ''
      t.boolean :is_primary, null: false, default: false
      t.boolean :is_enabled, null: false, default: false
      t.timestamps
    end

    add_index :calendar_connection_calendars,
              [:calendar_connection_id, :external_id],
              unique: true,
              name: 'idx_cal_conn_cals_on_connection_and_external'

    create_table :calendar_events do |t|
      t.references :account, null: false, foreign_key: true
      t.references :calendar_connection, null: false, foreign_key: true
      t.string :external_calendar_id, null: false
      t.string :google_event_id, null: false
      t.string :etag
      t.string :summary
      t.datetime :start_at
      t.datetime :end_at
      t.string :html_link
      t.references :created_by, foreign_key: { to_table: :users }
      t.references :updated_by, foreign_key: { to_table: :users }
      t.references :contact, foreign_key: true
      t.references :conversation, foreign_key: true
      t.timestamps
    end

    add_index :calendar_events,
              [:calendar_connection_id, :google_event_id],
              unique: true,
              name: 'idx_calendar_events_on_connection_and_google_id'
    add_index :calendar_events, [:account_id, :conversation_id]
  end
end
