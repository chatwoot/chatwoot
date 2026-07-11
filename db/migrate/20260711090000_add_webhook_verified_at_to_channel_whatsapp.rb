class AddWebhookVerifiedAtToChannelWhatsapp < ActiveRecord::Migration[7.1]
  def change
    add_column :channel_whatsapp, :webhook_verified_at, :datetime
  end
end
