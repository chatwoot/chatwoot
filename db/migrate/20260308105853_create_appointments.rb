class CreateAppointments < ActiveRecord::Migration[7.1]
  def change
    create_table :appointments do |t|
      t.references :account, null: false, foreign_key: true
      t.references :conversation, null: false, foreign_key: true
      t.references :contact, null: false, foreign_key: true
      t.bigint :created_by_id, null: false
      t.references :message, foreign_key: true
      t.string :provider, null: false
      t.integer :status, default: 0, null: false
      t.string :scheduling_url
      t.string :event_type_name
      t.string :event_type_uri
      t.datetime :scheduled_at
      t.string :external_event_id
      t.jsonb :payload, default: {}, null: false

      t.timestamps
    end

    add_index :appointments, :created_by_id
    add_index :appointments, :external_event_id, unique: true
    add_index :appointments, :status
    add_index :appointments, :provider
    add_index :appointments, :scheduled_at
    add_foreign_key :appointments, :users, column: :created_by_id
  end
end
