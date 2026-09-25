class CreateMobilePushTables < ActiveRecord::Migration[7.1]
  def change
    create_apps
    create_devices
    create_deliveries
  end

  private

  def create_apps
    create_table :mobile_apps do |t|
      t.references :inbox, null: false, foreign_key: { on_delete: :cascade }, index: { unique: true }
      t.string :name, null: false
      t.string :bundle_id, null: false
      t.string :team_id, null: false
      t.string :key_id, null: false
      t.text :private_key, null: false
      t.timestamps
    end
  end

  def create_devices
    create_table :mobile_push_devices do |t|
      t.references :mobile_app, null: false, foreign_key: { on_delete: :cascade }
      t.references :contact_inbox, null: false, foreign_key: { on_delete: :cascade }
      t.references :contact, null: false, foreign_key: { on_delete: :cascade }
      t.string :device_token, null: false
      t.string :environment, null: false
      t.string :name, null: false
      t.datetime :registered_at, null: false
      t.datetime :invalidated_at
      t.timestamps
    end
    add_index :mobile_push_devices, [:mobile_app_id, :environment, :device_token], unique: true, name: 'index_mobile_push_devices_on_token'
  end

  def create_deliveries
    create_table :mobile_push_deliveries do |t|
      t.references :mobile_push_device, null: false, foreign_key: { on_delete: :cascade }
      t.references :message, foreign_key: { on_delete: :cascade }
      t.string :status, null: false, default: 'pending'
      t.string :reason
      t.string :apns_id, null: false
      t.timestamps
    end
    add_index :mobile_push_deliveries, [:mobile_push_device_id, :message_id], unique: true, name: 'index_mobile_push_deliveries_on_message'
  end
end
