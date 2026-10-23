class AddLocationsToChannelWhatsapp < ActiveRecord::Migration[7.2]
  def change
    add_column :channel_whatsapp, :locations, :jsonb, default: []
  end
end
