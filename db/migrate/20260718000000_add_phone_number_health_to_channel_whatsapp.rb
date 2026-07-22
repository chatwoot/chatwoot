class AddPhoneNumberHealthToChannelWhatsapp < ActiveRecord::Migration[7.1]
  def change
    add_column :channel_whatsapp, :phone_number_health, :jsonb, default: {}, null: false
    add_column :channel_whatsapp, :phone_number_health_checked_at, :datetime
    add_column :channel_whatsapp, :phone_number_health_error, :string, limit: 500
    add_index :channel_whatsapp, :phone_number_health_checked_at
  end
end
