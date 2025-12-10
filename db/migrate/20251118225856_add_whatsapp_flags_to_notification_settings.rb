class AddWhatsappFlagsToNotificationSettings < ActiveRecord::Migration[7.1]
  def change
    add_column :notification_settings, :whatsapp_flags, :integer, default: 0, null: false
  end
end
