class AddWebhookUrlToChannelWebWidget < ActiveRecord::Migration[7.0]
  def change
    add_column :channel_web_widgets, :webhook_url, :string
  end
end
