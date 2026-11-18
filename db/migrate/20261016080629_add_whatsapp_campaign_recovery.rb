class AddWhatsappCampaignRecovery < ActiveRecord::Migration[7.1]
  def change
    add_column :campaigns, :whatsapp_cursor, :bigint
    add_column :campaign_recipients, :send_attempted_at, :datetime
  end
end
