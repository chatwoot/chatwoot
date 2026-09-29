class CreateSdkTables < ActiveRecord::Migration[7.1]
  def change
    create_sdk_apps
    create_ios_configurations
    create_android_configurations
    create_devices
    create_deliveries
  end

  private

  def create_sdk_apps
    create_table :sdk_apps do |t|
      t.references :account, null: false
      t.references :inbox, null: false
      t.string :app_id, null: false, index: { unique: true }
      t.string :name, null: false
      t.timestamps
    end
  end

  def create_ios_configurations
    create_table :sdk_ios_configurations do |t|
      t.boolean :enabled, null: false, default: true
      t.references :sdk_app, null: false, index: { unique: true }
      t.string :bundle_id, null: false
      t.string :team_id, null: false
      t.string :key_id, null: false
      t.text :private_key, null: false
      t.timestamps
    end
  end

  def create_android_configurations
    create_table :sdk_android_configurations do |t|
      t.boolean :enabled, null: false, default: true
      t.references :sdk_app, null: false, index: { unique: true }
      t.string :package_name, null: false
      t.string :project_id, null: false
      t.text :service_account, null: false
      t.timestamps
    end
  end

  def create_devices
    create_table :sdk_push_devices do |t|
      t.references :sdk_app, null: false
      t.references :contact_inbox, null: false
      t.references :contact, null: false
      t.string :platform, null: false
      t.string :device_token, null: false
      t.string :environment, null: false
      t.string :name, null: false
      t.datetime :registered_at, null: false
      t.datetime :invalidated_at
      t.timestamps
    end
    add_index :sdk_push_devices, [:sdk_app_id, :platform, :environment, :device_token], unique: true, name: 'index_sdk_push_devices_on_token'
  end

  def create_deliveries
    create_table :sdk_push_deliveries do |t|
      t.references :sdk_push_device, null: false
      t.references :message
      t.string :status, null: false, default: 'pending'
      t.string :reason
      t.string :apns_id, null: false
      t.timestamps
    end
    add_index :sdk_push_deliveries, [:sdk_push_device_id, :message_id], unique: true, name: 'index_sdk_push_deliveries_on_message'
  end
end
