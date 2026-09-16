class AddBusinessManagementTokenToChannelWhatsapp < ActiveRecord::Migration[7.1]
  def change
    add_column :channel_whatsapp, :business_management_token, :text
  end
end
