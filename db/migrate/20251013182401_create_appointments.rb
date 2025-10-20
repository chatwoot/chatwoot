class CreateAppointments < ActiveRecord::Migration[7.1]
  def change
    create_table :appointments do |t|
      t.string :location
      t.text :description
      t.datetime :start_time
      t.datetime :end_time
      t.boolean :assisted, default: false, null: false
      t.string :access_token
      t.references :contact, null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true

      t.timestamps
    end

    add_index :appointments, :access_token, unique: true
  end
end
