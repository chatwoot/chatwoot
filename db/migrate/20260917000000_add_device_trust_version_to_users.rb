class AddDeviceTrustVersionToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :device_trust_version, :integer, default: 0, null: false
  end
end
