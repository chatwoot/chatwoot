class AddWebhookUrlToChannelFacebookPages < ActiveRecord::Migration[7.0]
  def change
    add_column :channel_facebook_pages, :webhook_url, :string
  end
end
