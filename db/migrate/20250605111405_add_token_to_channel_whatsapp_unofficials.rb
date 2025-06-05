class AddTokenToChannelWhatsappUnofficials < ActiveRecord::Migration[7.0]
  def change
    add_column :channel_whatsapp_unofficials, :token, :string
  end
end
