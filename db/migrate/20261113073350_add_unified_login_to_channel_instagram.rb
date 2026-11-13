class AddUnifiedLoginToChannelInstagram < ActiveRecord::Migration[8.0]
  def change
    add_column :channel_instagram, :auth_type, :string, null: false, default: 'instagram_login'
    add_column :channel_instagram, :configuration_id, :string
    change_column_null :channel_instagram, :expires_at, true
  end
end
