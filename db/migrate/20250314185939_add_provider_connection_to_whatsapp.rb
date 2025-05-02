class AddProviderConnectionToWhatsapp < ActiveRecord::Migration[7.0]
  def change
    add_column :channel_whatsapp, :provider_connection, :jsonb, default: {}
  end
end
