class AddSecurityTokenToChannelWhatsappZapi < ActiveRecord::Migration[7.0]
  def change
    add_column :channel_whatsapp_zapi, :security_token, :string
  end
end
