class AddCalendarIdempotencyAndContactIndex < ActiveRecord::Migration[7.0]
  def change
    add_column :calendar_events, :idempotency_key, :string
    add_index :calendar_events, [:account_id, :idempotency_key],
              unique: true,
              where: 'idempotency_key IS NOT NULL',
              name: 'index_calendar_events_on_account_id_and_idempotency_key'
    add_index :calendar_events, [:account_id, :contact_id],
              name: 'index_calendar_events_on_account_id_and_contact_id'
  end
end
